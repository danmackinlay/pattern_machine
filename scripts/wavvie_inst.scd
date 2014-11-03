{|state, i|
	state.make({
		var strip;
		strip = PSWavvieStrip.new(
			i, parent:nil, numChannels:2, clock: nil, group:nil, bus:nil, state:state);
		~strip = strip;
		CmdPeriod.doOnce({ strip.cleanup;});
		~loopbuf = Buffer.alloc(~server, ~server.sampleRate * ~sampleDur, 1);
		strip.addFreeable({ state.loopbuf });
		~modbus = Bus.control(~server,1);
		strip.addFreeable({ state.modbus });
		~loopphasebus = Bus.control(~server, 1);
		strip.addFreeable({ state.loopphasebus });
		s.sync;
		~recsynth = (
			instrument: \ps_bufwr_resumable__1x1,
			in: ~inbus,
			bufnum: ~loopbuf,
			phasebus: ~loopphasebus,
			fadetime: 0.05,
			group: strip.sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).play;
		~cleanupList.add({ state.recsynth.free });
		//record input
		~rec = {|self, dur=10.0|
			self.recsynth.set(\t_rec, dur);
		};
		//channel fx
		~reverb = (
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
		).play;
		~cleanupList.add({ state.reverb.free });
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