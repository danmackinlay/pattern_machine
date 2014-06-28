var inbus, outbus;
var ingroup, fxgroup, postgroup;
var loopbufs, loopsynths, loopphasebuses;
var sourcebuf, sourcesound, limiter;
var control;
var vox1channel, vox2channel, vox3channel, vox4channel, mixingboard;
var tempo, beatTime, clock;
var state;
var reverb1, reverb2, reverb3, reverb4;
var pitchrollyawaccel, metaparams, params, paramUpdaters, paramWatcher;
var mididefs;

~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
this.executeFile(~pmscripts +/+ "apoca_synths.scd");

tempo = 80.0;
beatTime = 60.0/tempo;
clock = TempoClock.default.tempo_(tempo/60.0);

state = (
	clock: clock,
	tempo: tempo,
	beatTime: beatTime,
	paramDirty: false,
);
fork {
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

	this.executeFile(~pmscripts +/+ "apoca_midi.scd").value(state).do(state.mididefs.add(_));
	CmdPeriod.doOnce { mididefs.do(MIDIdef(_).free) };

	//basic overall mixer setup
	inbus = Bus.audio(s,1);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	CmdPeriod.doOnce { inbus.free };
	outbus = Bus.new(\audio, 0, 2, s);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");

	s.sync;
	sourcebuf = ~sampsetbufdict[\tuneful][0];
	vox1channel = MixerChannel.new("echette1", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { vox1channel.free };
	vox2channel = MixerChannel.new("echette2", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce {vox2channel.free };
	vox3channel = MixerChannel.new("bonus1", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { vox3channel.free };
	vox4channel = MixerChannel.new("bonus2", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { vox4channel.free };
	s.sync;
	mixingboard = MixingBoard.new("apocalypse", nil,
		vox1channel,
		vox2channel,
		vox3channel,
		vox4channel);
	CmdPeriod.doOnce { mixingboard.free };
	s.sync;
	ingroup = Group.new(s, \addToHead);
	CmdPeriod.doOnce { ingroup.free };
	postgroup = Group.new(s, \addAfter);
	CmdPeriod.doOnce { postgroup.free };

	//channel fx
	reverb1 = vox1channel.playfx(\ps_gverb__2_2, [
		\index, 1,
		\wet, 0.2,
		\damping, 0.4,
		\revtime, 0.8,
		\roomsize, 170,
	]);
	reverb2 = vox2channel.playfx(\ps_gverb__2_2, [
		\index, 2,
		\wet, 0.7,
		\damping, 0.3,
		\revtime, 2.0,
		\roomsize, 190,
	]);
	reverb3 = vox3channel.playfx(\ps_gverb__2_2, [
		\index, 3,
		\wet, 0.3,
		\damping, 0.8,
		\revtime, 1.0,
		\roomsize, 210,
	]);
	reverb4 = vox4channel.playfx(\ps_gverb__2_2, [
		\index, 4,
		\wet, 0.8,
		\damping, 0.3,
		\revtime, 4,
		\roomsize, 180,
	]);
	s.sync;

	//sample-loop action
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

	control = Bus.control(s, 8);
	CmdPeriod.doOnce { control.free };
	s.sync;

	state.putAll((
		outbus: outbus,
		inbus: inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		limiter: limiter,
		ingroup: ingroup,
		loopsynths: loopsynths,
		loopbufs: loopbufs,
		loopphasebuses: loopphasebuses,
		vox1channel: vox1channel,
		vox2channel: vox2channel,
		vox3channel: vox3channel,
		vox4channel: vox4channel,
		fxgroup: fxgroup,
		reverb1: reverb1,
		reverb2: reverb2,
		reverb3: reverb3,
		reverb4: reverb4,
		mixingboard: mixingboard,
		postgroup: postgroup,
		sourcebuf: sourcebuf,
		sourcesound: sourcesound,
		control: control,
		vox1state: Event.new(n:30,proto:state),
		vox1: List.new,
		vox2state: Event.new(n:30,proto:state),
		vox2: List.new,
		vox3state: Event.new(n:30,proto:state),
		vox3: List.new,
		vox4state: Event.new(n:30,proto:state),
		vox4: List.new,
	));
	~state=state;
};

~killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
~killAll = {[~state.vox1,~state.vox2,~state.vox3,~state.vox4].do({|thing| thing.postln;~killList.value(thing)})};
