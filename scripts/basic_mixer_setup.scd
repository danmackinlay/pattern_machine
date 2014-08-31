// core setup script; will only return if invoked in a forked thread
//TODO use BusDict to tame MixerChannel business
{|state| {state.make({
	~tempo = ~tempo ? 80.0;
	~beatTime = 60.0/~tempo;
	~clock = ~clock ?? {TempoClock.default.tempo_(~tempo/60.0);};
	~ninputchannelstrips = ~ninputchannelstrips ? 2;
	~ninstchannelstrips = ~ninstchannelstrips ? 4;
	~server = ~server ? Server.default;
	//basic overall mixer setup
	~extinbus = Bus.newFrom(~server.inputBus,0,1);
	~inbus = Bus.audio(~server, ~ninputchannelstrips);
	CmdPeriod.doOnce({ ~inbus.free }.inEnvir);
	~outbus = Bus.new(\audio, 0, 2, ~server);
	CmdPeriod.doOnce({ ~outbus.free }.inEnvir);
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
		~inputchannelstrips.wrapAt(i).newPostSend(ch,1);
		ch;
	});
	~mixingboard = MixingBoard.new("parkingsun", nil,
		~inputchannelstrips ++
		~instchannelstrips ++
		~masterchannel);
	CmdPeriod.doOnce({ ~mixingboard.free }.inEnvir);

	//In case I don't want to sing:
	~sourcesound = ~inputchannel.play((
		instrument: \playbuf_soundin__1x1,
		tempo: PContext(state, \tempo),
		in: ~extinbus,
		bufnum: ~defaultSourcebuf,
		livefade: 0.0,
		loop: 1,
		sendGate: false,//persist
	));
	CmdPeriod.doOnce({ ~sourcesound.free }.inEnvir);

	~limiter = ~masterchannel.playfx((
		instrument: \limi__2x2,
	));
	CmdPeriod.doOnce({ ~limiter.free }.inEnvir);
	s.sync;

	state;
})}.forkIfNeeded};
