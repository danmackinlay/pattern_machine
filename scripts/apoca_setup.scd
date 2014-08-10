// core setup script; must be invoked by a forked thread.

{|state|
	var inbus, outbus;
	var ingroup, fxgroup, postgroup;
	var loopbufs, loopsynths, loopphasebuses;
	var sourcebuf, sourcesound, limiter;
	var parambuses;
	var mixingboard, masterchannel;
	var tempo, beatTime, clock;
	var mididefs;
	var metaparamMap, paramUpdater;

	tempo = 80.0;
	beatTime = 60.0/tempo;
	clock = TempoClock.default.tempo_(tempo/60.0);

	state.putAll((
		clock: clock,
		tempo: tempo,
		beatTime: beatTime,
		density: 1,
		chaos: 0,
	));

	//sample loading
	this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(state, ~sczamples);
	//synth loading
	this.executeFile(~pmscripts +/+ "apoca_synths.scd").value(state);
	s.sync;

	//UI interaction stuff
	mididefs = List.new;

	metaparamMap = PSMetaParamMap.new(inDims:3, outDims:10);
	paramUpdater = PSParamForwarder(metaparamMap, 0.05);
	CmdPeriod.doOnce { paramUpdater.free };
	state.metaparamMap = metaparamMap;
	state.paramUpdater = paramUpdater;
	state.mididefs = mididefs;

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
	masterchannel = MixerChannel.new(\master, s, 2, 2, outbus: outbus);
	s.sync;
	mixingboard = MixingBoard.new("apocalypse", nil, masterchannel);
	CmdPeriod.doOnce { mixingboard.free };
	s.sync;
	ingroup = Group.new(s, \addToHead);
	CmdPeriod.doOnce { ingroup.free };
	postgroup = Group.new(s, \addAfter);
	CmdPeriod.doOnce { postgroup.free };

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

	limiter = (
	 	instrument: \limi__2,
	 	group: postgroup,
	 	outbus: outbus,
	).play;
	CmdPeriod.doOnce { limiter.free };
	s.sync;

	state.putAll((
		outbus: outbus,
		inbus: inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		limiter: limiter,
		ingroup: ingroup,
		fxgroup: fxgroup,
		mixingboard: mixingboard,
		postgroup: postgroup,
		sourcebuf: sourcebuf,
		sourcesound: sourcesound,
	));
	~killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
	~killAll = {~state.voices.do({|thing| thing.postln;~killList.value(thing)})};

	state;
};
