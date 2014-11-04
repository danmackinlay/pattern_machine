{|state, i|
	state.make({
		var strip;
		strip = PSStrip.new(
			i, parent:nil, numChannels:2, clock: nil, group:nil, bus:nil, state:state);
		~strip = strip;
		CmdPeriod.doOnce({ strip.cleanup;});

		~loopbuf = strip.freeable(Buffer.alloc(~server, ~server.sampleRate * ~sampleDur, 1));
		~modbus = strip.freeable(Bus.control(~server,1));
		~loopphasebus = strip.freeable(Bus.control(~server, 1));
		s.sync;
		~recsynth = strip.freeable((
			instrument: \ps_bufwr_resumable__1x1,
			in: ~inbus,
			bufnum: ~loopbuf,
			phasebus: ~loopphasebus,
			fadetime: 0.05,
			group: strip.sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).play);
		//record input
		~rec = {|self, dur=10.0|
			self.recsynth.set(\t_rec, dur);
		};
		//channel fx
		~reverb = strip.freeable((
			instrument: \ps_gverb__2x2,
			group: strip.fxgroup,
			server: ~server,
			addAction: \addToHead,
			sendGate: false,//persist
			out: strip.bus,
			index: 1,
			wet: 0.2,
			damping: 0.4,
			revtime: 0.8,
			roomsize: 170,
		).play);
		//channel fx
		~jack = (
			instrument: \jack__2,
			group: strip.mixergroup,
			server: ~server,
			addAction: \addToTail,
			sendGate: false,//persist
			in: strip.bus,
			out: state.masteroutbus,
		).play;
		~cleanupList.add({ state.jack.free });
		~parentevt = (
			type: \note,
			instrument: \ps_bufgrain_type_2__1x2,
			group: strip.sourcegroup,
			addAction: \addToTail,
			server: ~server,
			sendGate: false,
			out: strip.bus,
			now: ~loopphasebus.asMap,
			bufnum: ~loopbuf,
		);
	});
}