// My most common mixing setup
// will only return if invoked in a forked thread
{|state| {state.make({
	~ninputs = ~ninputs ? 1;
	~ninsts = ~ninsts ? 4;
	~sampleDur = ~sampleDur ? 60;
	~nextVoice = 0;
	~voiceStates = List.fill(~ninsts, nil);

	~offset = ~offset ? 0.0;
	~clock = ~clock ? TempoClock.default;
	//propagates tempo variables into various derivatives and synths
	state.updateTempo={|self|
		\updatetempo.postln;
		//self.postln;
		self.bpm = self.bpm ? 80.0;
		self.tempo = 60.0/self.bpm;
		self.beatTime = self.tempo.reciprocal;
		self.loopBeats = self.loopBeats ? 8.0;
		self.loopTime = self.beatTime * self.loopBeats;
		(self.clock.tempo != self.tempo).if({
			self.clock.tempo_(self.tempo);
		});
		self.sourcesounds.notNil.if({
			self.sourcesounds.do({|synth|
				synth.set(\looptime, self.loopTime);
			});
		});
		self.voiceStates.do({|voicestate|
			voicestate.notNil.if({ voicestate.updateTempo.()});
		});
	};
	state.updateTempo.();
	~ninputs = ~ninputs ? 1;
	~ninsts = ~ninsts ? 4;
	~nparams = ~nparams ? 32;

	~server = ~server ? Server.default;
	~maingroup = Group.new(~server,addAction:\addToHead);
	CmdPeriod.doOnce({ state.maingroup.free });

	s.sync;
	~inputgroup = Group.new(~maingroup, addAction:\addToHead);
	~instgroup = Group.new(~maingroup, addAction:\addToTail);
	s.sync;
	~mastergroup = Group.new(~maingroup, addAction:\addToTail);

	~extinbus = Bus.newFrom(~server.inputBus,0,~ninputs);
	~masteroutbus = Bus.new(\audio, 0, 2, ~server);
	~inbus = Bus.audio(~server, ~ninputs);
	CmdPeriod.doOnce({ state.inbus.free });

	~instbus = Bus.audio(~server, ~ninsts * 2);
	CmdPeriod.doOnce({ state.instbus.free });

	~parambus = Bus.control(~server, ~nparams);
	CmdPeriod.doOnce({ state.parambus.free });

	~server.sync;

	~inbuses = ~ninputs.collect({|i| ~inbus.subBus(i, 1)});
	//~instbuses = ~ninsts.collect({|i| ~instbus.subBus(i*2, 2)});
	//~parambuses = ~nparams.collect({|i| ~parambus.subBus(i, 1)});
	~instbusallocator = BusAllocator.new(~instbus, 2);
	~parambusallocator = BusAllocator.new(~parambus);

	s.sync;
	~samples.notNil.if({
		~defaultSourcebuf = ~samples.at(0)
	}, {
		~defaultSourcebuf = 0
	});

	~inputgain = (
		instrument: \limi__1x1,
		pregain: 10.dbamp, //BOOOM
		out: ~extinbus,
		group: ~inputgroup,
		server: ~server,
		addAction: \addToHead,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce({ state.inputgain.free) });

	//In case I don't want to sing:
	~sourcesounds = ~inbuses.collect({|bus, i| (
		instrument: \bufrd_or_live__1x1,
		looptime: ~loopTime,
		offset: ~offset,
		in: ~extinbus.subBus(i,1),
		out: bus,
		group: ~inputgroup,
		server: ~server,
		addAction: \addToTail,
		bufnum: ~defaultSourcebuf,
		livefade: 0.0,
		loop: 1,
		sendGate: false,//persist
	).play;});
	CmdPeriod.doOnce({ state.sourcesounds.do({|synth| synth.free}) });

	~limiter = (
		instrument: \limi__2x2,
		out: ~masteroutbus,
		group: ~mastergroup,
		server: ~server,
		addAction: \addToTail,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce({ state.limiter.free });

	~listeners = ~instbuses.collect({|bus| (
		instrument: \jack__2,
		in: bus,
		out: ~masteroutbus,
		group: ~mastergroup,
		server: ~server,
		addAction: \addToHead,
		sendGate: false,//persist
	).play;});

	s.sync;

	state;
})}.forkIfNeeded};
