// My most common mixing setup
// will only return if invoked in a forked thread
{|state| {state.make({
	~bpm = ~bpm ? 80.0;
	~tempo = 60.0/~bpm;
	~clock = ~clock ? TempoClock.default;
	(~clock.tempo != ~tempo).if({
		~clock.tempo_(~tempo);
	});
	~ninputs = ~ninputs ? 1;
	~ninsts = ~ninsts ? 4;
	~server = ~server ? Server.default;
	~maingroup = Group.new(~server,addAction:\addToHead);
	CmdPeriod.doOnce({ state.maingroup.free });

	s.sync;
	~inputgroup = Group.new(~maingroup, addAction:\addToHead);
	~instgroup = Group.new(~maingroup, addAction:\addToTail);

	~extinbus = Bus.newFrom(~server.inputBus,0,~ninputs);
	~masteroutbus = Bus.new(\audio, 0, 2, ~server);

	~inbus = Bus.audio(~server, ~ninputs);
	CmdPeriod.doOnce({ state.inbus.free });

	~instbus = Bus.audio(~server, ~ninsts * 2);
	CmdPeriod.doOnce({ state.instbus.free });

	~server.sync;

	~inbuses = ~ninputs.collect({|i| ~inbus.subBus(i, 1)});
	~instbuses = ~ninsts.collect({|i| ~instbus.subBus(i*2, 2)});

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
	CmdPeriod.doOnce({ state.inputgain.do({|synth| synth.free}) });

	//In case I don't want to sing:
	~sourcesounds = ~inbuses.collect({|bus, i| (
		instrument: \bufrd_or_live__1x1,
		looptime: 8.0/~tempo, //2 bars
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
	CmdPeriod.doOnce({ state.sourcesound.do({|synth| synth.free}) });

	~limiter = (
		instrument: \limi__2x2,
		out: ~masteroutbus,
		group: ~outputgroup,
		server: ~server,
		addAction: \addToTail,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce({ state.limiter.free });
	s.sync;

	state;
})}.forkIfNeeded};
