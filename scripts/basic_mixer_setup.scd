// My most common mixing setup
// will only return if invoked in a forked thread
{|strip| {
	strip.state.make({
	~inputgain = (
		instrument: \limi__1x1,
		pregain: (-6).dbamp,
		out: ~extinbus,
		group: strip.sourcegroup,
		server: ~server,
		addAction: \addToHead,
		sendGate: false,//persist
	).play;

	//In case I don't want to sing:
	~sourcesounds = ~inbuses.collect({|bus, i| (
		instrument: \bufrd_or_live__1x1,
		looptime: ~loopTime,
		offset: ~offset,
		in: ~extinbus.subBus(i,1),
		out: bus,
		group: strip.sourcegroup,
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
		group: strip.mixergroup,
		server: ~server,
		addAction: \addToTail,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce({ state.limiter.free });

	~listeners = ~instbuses.collect({|bus| (
		instrument: \jack__2,
		in: bus,
		out: ~masteroutbus,
		group: strip.mixergroup,
		server: ~server,
		addAction: \addToHead,
		sendGate: false,//persist
	).play;});

	s.sync;

	state;
})}.forkIfNeeded};
