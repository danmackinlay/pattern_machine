// live sampling strip; has a buffer attached
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
		recsynth = PSSamplingSynth();
		this.add(recsynth);
	}
}