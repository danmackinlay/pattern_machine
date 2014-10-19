// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// will need to extend Integer, SimpleNumber etc
// should I sort this list?
PSquama[slot] : RawArray {
	var <tuning;
	var <octaveRatio;
	var <nsteps;
	var <shadowtuning;

	*new { | tuning, octaveRatio = 2.0|
		var newguy;
		[\tuning, tuning].postcs;
		newguy = super.new(tuning.size);
		tuning.do {| item | newguy.add(item) };
		[\newguy,newguy].postcs;
		^newguy.init(octaveRatio);
	}
	init {|myoctaveRatio|
		octaveRatio = myoctaveRatio;
	}
	updateShadowTuning {
		nsteps = tuning.size-1;
		shadowtuning = FloatArray.newFrom(nsteps).add(tuning[0]*octaveRatio)
		^this
	}
	as { |class|
		^this.tuning.as(class)
	}
	size {
		^tuning.size;
	}

	blendAt { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = index - (div*nsteps);
		^tuning.blendAt(mod) * (octaveRatio**div)
	}

	at { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = (index - (div*nsteps)).asInt;
		^tuning.at(mod) * (octaveRatio**div)
	}

	wrapAt { |index|
		^tuning.wrapAt(index)
	}

	== { arg that;
		^this.compareObject(that, #[\tuning, \octaveRatio])
	}

	hash {
		^this.instVarHash(#[\tuning, \octaveRatio])
	}

	storeArgs { ^[tuning, octaveRatio] }

	printOn { |stream|
		this.storeOn(stream)
	}
}
