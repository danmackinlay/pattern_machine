// live sampling version
PSSamplingStrip : PSStrip {
	var <recsynth;
	*new {arg id, parent, numChannels, clock, group, bus, state;
		^super.new(
			id, parent, numChannels, clock, group, bus, state
		).initPSSamplingStrip;
		
	}
	rec {|dur=10.0|
		recsynth.set(\t_rec, dur);
	}
	initPSSamplingStrip {
		recsynth = this.freeable((
			instrument: \ps_bufwr_resumable__1x1,
			in: ~inbus,
			bufnum: ~loopbuf,
			phasebus: ~loopphasebus,
			fadetime: 0.05,
			group: strip.sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).play);
	}
}