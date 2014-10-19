// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// will need to extend Integer, SimpleNumber etc
// should I sort this list?
PSquama {
	var <tuning;
	var <octaveRatio;
	var <nsteps;
	var <shadowtuning;

	*linear { | tuning, octaveRatio = 2.0|
		^super.newCopyArgs(tuning, octaveRatio).updateShadowTuning;
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
	put {|index, stuff|
		tuning.put(index, stuff);
		this.updateShadowTuning;
	}
	at { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = (index - (div*nsteps)).asInt;
		^tuning.at(mod) * (octaveRatio**div)
	}

	blendAt { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = index - (div*nsteps);
		^shadowtuning.blendAt(mod) * (octaveRatio**div)
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
