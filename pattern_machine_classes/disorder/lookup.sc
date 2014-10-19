// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// will need to extend Integer, SimpleNumber etc
// should I sort this list?
PSquama[slot] : RawArray {
	var <octaveRatio;
	var <nsteps;
	var <shadowtuning;

	*new { | tuning, octaveRatio = 2.0|
		var newguy;
		newguy = super.new(tuning.size);
		tuning.do {| item | newguy.add(item) };
		^newguy.init(octaveRatio);
	}
	init {|myoctaveRatio|
		octaveRatio = myoctaveRatio;
		this.updateShadowTuning;
		^this;
	}
	updateShadowTuning {
		nsteps = this.size-1;
		shadowtuning = FloatArray.newFrom(nsteps).add(this.at(0)*octaveRatio);
		^this
	}
	put {|index, stuff|
		super.put(index, stuff);
		this.updateShadowTuning;
		^this;
	}
	at { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = (index - (div*nsteps)).asInt;
		[\divmod, \div, \mod].postcs;
		^shadowtuning.at(mod) * (octaveRatio**div)
	}
	blendAt { |index|
		//probably only makes sense if sorted.
		var div, mod;
		div = (index/nsteps).floor;
		mod = index - (div*nsteps);
		^shadowtuning.blendAt(mod) * (octaveRatio**div)
	}
	wrapAt { |index|
		^super.wrapAt(index)
	}

	storeArgs { ^[this.asArray, octaveRatio] }

	printOn { |stream|
		this.storeOn(stream)
	}
}
