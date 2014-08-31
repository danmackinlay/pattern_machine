// core setup script; will only return if invoked in a forked thread
{|state| {state.make({
	~tempo = ~tempo ? 80.0;
	~beatTime = 60.0/~tempo;
	~clock = ~clock ?? {TempoClock.default.tempo_(~tempo/60.0);};
	~nchannelstrips = ~nchannelstrips ? 4;
	~server = ~server ? Server.default;
	//basic overall mixer setup
	~extinbus = Bus.newFrom(~server.inputBus,0,1);
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
	~channelstrips = ~nchannelstrips.collect({|i|
		MixerChannel.new(\channel ++ i, ~server, 2, 2, outbus: ~outbus)
	});
	~inputchannel = MixerChannel.new(\input, ~server, 2, 2, outbus: ~channelstrips[0]);
	~mixingboard = MixingBoard.new("parkingsun", nil,
		~channelstrips,
		~inputchannel,
		~masterchannel);
	CmdPeriod.doOnce({ ~mixingboard.free }.inEnvir);
	
	//In case I don't want to sing:
	~sourcesound = ~inputchannel.play((
		instrument: \playbuf_soundin__1x1,
		in: ~extinbus,
		bufnum: ~defaultSourcebuf,
		livefade: 0.0,
		loop:1,
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
