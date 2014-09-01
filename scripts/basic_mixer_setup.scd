// core setup script; will only return if invoked in a forked thread
//TODO use BusDict to tame MixerChannel business
{|state| {state.make({
	~bpm = ~bpm ? 80.0;
	~tempo = 60.0/~bpm;
	~clock = ~clock ? TempoClock.default;
	(~clock.tempo != ~tempo).if({
		~clock.tempo_(~tempo);
	});
	~ninputchannelstrips = ~ninputchannelstrips ? 2;
	~ninstchannelstrips = ~ninstchannelstrips ? 4;
	~server = ~server ? Server.default;
	//basic overall mixer setup
	~extinbus = Bus.newFrom(~server.inputBus,0,1);
	~inbus = Bus.audio(~server, ~ninputchannelstrips);
	CmdPeriod.doOnce({ ~inbus.free });
	~outbus = Bus.new(\audio, 0, 2, ~server);
	CmdPeriod.doOnce({ state.outbus.free });
	s.sync;
	~samples.notNil.if({
		~defaultSourcebuf = ~samples.at(0)
	}, {
		~defaultSourcebuf = 0
	});
	~masterchannel = MixerChannel.new(\master, ~server, 2, 2, outbus: ~outbus);
	~inputchannelstrips = ~ninputchannelstrips.collect({|i|
		var ch = MixerChannel.new(\input ++ i, ~server, 1, 2, outbus: ~inbus.subBus(i,1));
		ch;
	});
	//Weird that I need to send a 2-channel send - I think sends only join at the FX bus?
	~instchannelstrips = ~ninstchannelstrips.collect({|i|
		var ch = MixerChannel.new(\channel ++ i, ~server, 1, 2, outbus: ~masterchannel);
		//~inputchannelstrips.wrapAt(i).postcs;
		//Force execution order
		~inputchannelstrips.do({|inp|
			ch.receivesSignalFrom(inp);
		});
		ch;
	});
	~basicchannels = ~inputchannelstrips ++
		~instchannelstrips ++
		~masterchannel;
	~mixingboard = MixingBoard.new("parkingsun", nil, ~basicchannels);
	CmdPeriod.doOnce({{
		~state.mixingboard.mixers.do({|mixergui| {mixergui.free(true)}.try(_.postcs) ;});
		//state.basicchannels.do({|mchan| {mchan.free}.try(_.postcs);});
		state.mixingboard.free;
	}.defer});

	//In case I don't want to sing:
	~sourcesounds = ~inputchannelstrips.collect({|strip| strip.play((
		instrument: \playbuf_soundin__1x1,
		//clocktempo: PContext(state, \tempo),
		in: ~extinbus,
		bufnum: ~defaultSourcebuf,
		livefade: 0.0,
		loop: 1,
		sendGate: false,//persist
	))});
	CmdPeriod.doOnce({ state.sourcesound.free });

	~limiter = ~masterchannel.playfx((
		instrument: \limi__2x2,
	));
	CmdPeriod.doOnce({ state.limiter.free });
	s.sync;

	state;
})}.forkIfNeeded};
