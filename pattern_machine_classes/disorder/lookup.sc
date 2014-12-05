// support non-integer Scale+Tuning-like things for e.g. delay times and ratios etc, that don't naturally look like MIDI.
// TODO: make *blending* exponential for the exp version
// TODO: make this suit the ControlSpec interface; subclass even
//    Does ArrayWarp already get us this behaviour?

//exp version
PSquama {
	var <tuning;
	var <octaveStep;
	var <nsteps;
	var <shadowtuning;

	*exp { | tuning, octaveStep = 2.0|
		^super.new.init(tuning, octaveStep).updateShadowTuning;
	}
	*lin { | tuning, octaveStep = 16|
		^PSquamaLin.new.init(tuning, octaveStep).updateShadowTuning;
	}
	init {|mytuning, myoctaveStep|
		tuning = mytuning;
		octaveStep = myoctaveStep;
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
/*
I don't subclass Warp but ControlSpec,
because Warps are isomorphisms [0,1] to [0,1] stretched post hoc using "min" and "max",
which is not natural for e.g. bar steps
although one could make it work by modifying the two in sync
Should I sort the steps? 
Mostly doesn't make sense without
Should I apply warp to interpolation? I feel I should.
TODO: make this a little simpler and more consistent by constraining to the steps thing AFTER all warping
TODO: implement partial interpolation
TODO: implement unmap
*/
PSArrayControlSpec : ControlSpec {
	var <steps;
	var <>interp;
	*new {
		arg steps, interp=0.0, warp='lin', default, units, grid;
		^super.new(minval: 0,
			maxval: steps.size-1,
			warp: warp,
			step: 0.0,
			default: default,
			units: units,
			grid: grid
		).steps_(steps.asArray).interp_(interp.asFloat);
	}
	*newFrom { arg similar;
		^this.new(similar.steps, similar.interp, similar.warp.asSpecifier,
			similar.default, similar.units, similar.grid)
	}

	storeArgs { ^[steps, interp, warp.asSpecifier, default, units, grid] }

	//NB not robust against mutation of collection. oh well.
	steps_ {
		arg v;
		steps = v.asArray;
		this.updateRanges;
		this.changed(\steps);
	}
	init {
		warp = warp.asWarp(this);
	}
	updateRanges {
		minval = 0;
		maxval = steps.size-1;
		clipLo = steps.minItem;
		clipHi = steps.maxItem;
	}
	// should this constrain to list values?
	constrain { arg value;
		^value.asFloat.clip(clipLo, clipHi).nearestInList(step)
	}
	map { arg val;
		var indx;
		indx = warp.map(val.clip(0.0, 1.0));
		interp.asBoolean.not.if({
			indx = indx.round(1);
		});
		^steps.blendAt(indx);
	}
	unmap { arg indx;
		var val = steps.indexInBetween(val.clip(clipLo, clipHi));
		// maps a value from spec range to [0..1]
		interp.asBoolean.not.if({
			val = val.round(1/(steps.size-1));
		});
		^warp.unmap(val);
	}
}