// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// will need to extend Integer, SimpleNumber etc
// TODO: make *blending* exponential for the exp version

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
		nsteps = tuning.size;
		shadowtuning = FloatArray.newFrom(nsteps).add(this.prAt(0,1));
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
		div = (index/nsteps).floor.asInt;
		mod = index - (div*nsteps);
		^this.prAt(mod, div);
	}
	prAt{|degree, octave|
		^tuning.at(degree) * (octaveStep**octave)
	}
	blendAt { |index|
		var div, mod;
		div = (index/nsteps).floor.asInt;
		mod = index - (div*nsteps);
		^this.prBlendAt(mod, div)
	}
	prBlendAt{|degree, octave|
		^shadowtuning.blendAt(degree) * (octaveStep**octave)
	}
	wrapAt { |index|
		^tuning.wrapAt(index)
	}
	unif {|p|
		/*
		uniform lookup, as if this were a discrete pdf
		same as choose, but BYO lookup index in [0,1]. (further if you want)
		cribbed from my Array extn
		*/
		^this.at((p*nsteps).floor);
	}
	choose {
		^this.tuning.choose;
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
	prAt{|degree, octave|
		^tuning.at(degree) + (octaveStep*octave)
	}
	prBlendAt{|degree, octave|
		^shadowtuning.blendAt(degree) + (octaveStep*octave)
	}
}
