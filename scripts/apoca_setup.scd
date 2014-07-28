// core setup script; must be invoked by a forked thread.

{|state|
	var inbus, outbus;
	var ingroup, fxgroup, postgroup;
	var loopbufs, loopsynths, loopphasebuses;
	var sourcebuf, sourcesound, limiter;
	var parambuses;
	var voicechannels, mixingboard;
	var tempo, beatTime, clock;
	var reverbs;
	var pitchrollyawaccel, metaparams, params, paramUpdaters, paramWatcher;
	var mididefs;

	tempo = 80.0;
	beatTime = 60.0/tempo;
	clock = TempoClock.default.tempo_(tempo/60.0);

	state.putAll((
		clock: clock,
		tempo: tempo,
		beatTime: beatTime,
		paramDirty: false,
		density: 1,
		chaos: 0,
	));

	//sample loading
	this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(state, ~sczamples);
	//synth loading
	this.executeFile(~pmscripts +/+ "apoca_synths.scd").value(state);
	s.sync;

	//UI interaction stuff
	metaparams = FloatArray.fill(7,0.5);
	params = FloatArray.fill(32,0.5);
	pitchrollyawaccel = FloatArray.fill(4,0.5);
	paramUpdaters = List.new;
	mididefs = List.new;
	state.params = params;
	state.metaparams = metaparams;
	state.pitchrollyawaccel = pitchrollyawaccel;
	state.paramMap = PSRandomMap(inDims:7, outDims:32, phi:1.2);
	state.paramUpdaters = paramUpdaters;
	state.mididefs = mididefs;

	paramWatcher = Routine({|newinval|
		var lastposttime=0.0, delta=0.0;
		inf.do({|ix|
			state.paramDirty.if({
				state.paramDirty = false;
				(delta>10.0).if({
					[\wii_updating,state.metaparams, newinval, delta].postln;
					lastposttime = newinval;
				});
				state.params = state.paramMap.value(state.metaparams);
				state.paramUpdaters.do({|fn, i|
					fn.value(state.params[i]);
				});
			});
			newinval = 0.02.yield;
			delta = newinval-lastposttime;
		});
	}).play;
	CmdPeriod.doOnce { paramWatcher.free };
	state.paramWatcher = paramWatcher;

	this.executeFile(~pmscripts +/+ "apoca_wii.scd").value(state);
	//to disable:
	//OSCdef(\wii).free;
	CmdPeriod.doOnce { OSCdef(\wii).free };

	this.executeFile(~pmscripts +/+ "apoca_midi.scd").value(state ).do(state.mididefs.add(_));
	CmdPeriod.doOnce { mididefs.do(MIDIdef(_).free) };

	//basic overall mixer setup
	inbus = Bus.audio(s,1);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	CmdPeriod.doOnce { inbus.free };
	outbus = Bus.new(\audio, 0, 2, s);
	s.sync;
	voicechannels = 4.collect({|i|
		MixerChannel.new("vox" ++ i.asString, s, 2,2, outbus:outbus)
	});
	//is this one necessary?
	CmdPeriod.doOnce { voicechannels.do(_.free) };
	s.sync;
	mixingboard = MixingBoard.new("apocalypse", nil,
		*voicechannels,
	);
	CmdPeriod.doOnce { mixingboard.free };
	s.sync;
	ingroup = Group.new(s, \addToHead);
	CmdPeriod.doOnce { ingroup.free };
	postgroup = Group.new(s, \addAfter);
	CmdPeriod.doOnce { postgroup.free };

	//channel fx
	reverbs = voicechannels.collect({|chan, i|
		chan.playfx(\ps_gverb__2_2, [
			\index, 1,
			\wet, 0.2,
			\damping, 0.4,
			\revtime, 0.8,
			\roomsize, 170,
		]);
	});
	s.sync;

	// delay/loop action action
	loopbufs = Buffer.allocConsecutive(4, s, s.sampleRate * 10.0, 1);
	CmdPeriod.doOnce { loopbufs.do(_.free) };
	loopphasebuses = Bus.control(s, 4);
	CmdPeriod.doOnce { loopphasebuses.free };
	s.sync;

	//In case I don't want to sing:
	sourcesound = (
		instrument: \playbuf_soundin__1,
		in: 0,
		outbus: inbus,
		bufnum: sourcebuf,
		group: ingroup,
		livefade: 0.0,
		addAction: \addToHead,
		loop:1,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce { sourcesound.free };
	s.sync;

	//delay/loop input
	loopsynths = 4.collect({|i|(
		instrument: \ps_buf_delay_loop__1_1,
		outbus: inbus,
		bufnum: loopbufs[i],
		group: ingroup,
		wet: 0,
		deltime: beatTime*4,
		phasebus: loopphasebuses.subBus(i),
		addAction: \addToTail,
		sendGate: false,//persist
	).play;});
	CmdPeriod.doOnce { loopsynths.do(_.free) };
	s.sync;

	limiter = (
	 	instrument: \limi__2,
	 	group: postgroup,
	 	outbus: outbus,
	).play;
	CmdPeriod.doOnce { limiter.free };
	s.sync;

	parambuses = Bus.control(s, 8);
	CmdPeriod.doOnce { parambuses.free };
	s.sync;

	state.putAll((
		outbus: outbus,
		inbus: inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		limiter: limiter,
		ingroup: ingroup,
		loopsynths: loopsynths,
		loopbufs: loopbufs,
		loopphasebuses: loopphasebuses,
		voicechannels: voicechannels,
		fxgroup: fxgroup,
		reverbs: reverbs,
		mixingboard: mixingboard,
		postgroup: postgroup,
		sourcebuf: sourcebuf,
		sourcesound: sourcesound,
		parambuses: parambuses,
	));
	~killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
	~killAll = {~state.voices.do({|thing| thing.postln;~killList.value(thing)})};

	state;
};
