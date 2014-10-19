// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// will need to extend Integer, SimpleNumber etc
// TODO: make blending exponential

//exp version
PSquama {
	var <tuning;
	var <octaveStep;
	var <nsteps;
	var <shadowtuning;

	*exp { | tuning, octaveStep = 2.0|
		^super.newCopyArgs(tuning, octaveStep).updateShadowTuning;
	}
	*lin { | tuning, octaveStep = 16|
		^PSquamaLin.newCopyArgs(tuning, octaveStep).updateShadowTuning;
	}
	updateShadowTuning {
		nsteps = tuning.size-1;
		shadowtuning = FloatArray.newFrom(nsteps).add(this.pedanticAt(0,1));
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
		^this.pedanticAt(mod, div);
	}
	pedanticAt{|degree, octave|
		^tuning.at(degree) * (octaveStep**octave)
	}
	blendAt { |index|
		var div, mod;
		div = (index/nsteps).floor;
		mod = index - (div*nsteps);
		^this.pedanticBlendAt(mod, div)
	}
	pedanticBlendAt{|degree, octave|
		^shadowtuning.blendAt(degree) * (octaveStep**octave)
	}
	wrapAt { |index|
		^tuning.wrapAt(index)
	}

	== { arg that;
		^this.compareObject(that, #[\tuning, \octaveStep])
	}

	hash {
		^this.instVarHash(#[\tuning, \octaveStep])
	}

	storeArgs { ^[tuning, octaveStep] }

	printOn { |stream|
		this.storeOn(stream)
	}
}
PSquamaLin : PSquama {
	pedanticAt{|degree, octave|
		^tuning.at(degree) + (octaveStep*octave)
	}
	pedanticBlendAt{|degree, octave|
		^shadowtuning.blendAt(degree) + (octaveStep*octave)
	}
}
