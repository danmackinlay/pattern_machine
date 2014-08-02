/*
We create pattern with very open parameters, and infer a manifold of optimal sickness.

I'd like to do this in 2 different ways:

	* calculate a manifold that fits several desirable presets
	* generate random param manifolds/hyperplanes and interpolate

TODO: impose continuous sparseness
TODO: multiple set to avoid too many triggers
TODO: poll values and update params accordingly
TODO: make sure outputs are full range
*/

//Linear-congruantial-like pseudo RNG; not of course an RNG, but conveniently indexed
//for ease, generates in range [0.0,1.0]
PSSawMapGenerator {
	*new{|abase=3.117111, astep=0.77733, cbase=0.23335, cstep=0.3347|
		^Routine({|phi=0.1|
			var a=abase;
			var c=cbase;
			inf.do({
				phi = ((phi+c)*a).fold(0.0,1.0).yield;
				a=a+astep;
				c=c+cstep;
			});
		});
	}

}

//operates internally in range [-1.0,1.0]
PSMetaParamMap {
	var <inDims;
	var <outDims;
	var <gain;
	var <phi;
	var <abase;
	var <astep;
	var <cbase;
	var <cstep;
	var <combiners;
	var <prng;
	var <inParams;
	var <outParams;
	var <combinercoefs;//just for debugging
	var <paramDirty = true;
	
	*new{|inDims=3,
		outDims=5,
		gain=1.0,
		phi=0.1,
		abase=3.117111,
		astep=0.77733,
		cbase=0.23335,
		cstep=0.334|
		^super.newCopyArgs(
			inDims,
			outDims,
			gain,
			phi,
			abase, astep, cbase, cstep
		).initPSRandomMap;
	}
	initPSRandomMap {
		inParams = Array.fill(inDims, 0.0);
		outParams = Array.fill(outDims, 0.0);
		combinercoefs = Array.fill(outDims, {Array.fill(inDims,0.0)});
		prng = PSSawMapGenerator.new(abase,astep,cbase,cstep);
		this.genCombiners;
	}
	genCombiners {
		prng.reset;
		combiners = outDims.collect({|i|this.genCombiner(i)});
		this.value;
	}
	genCombiner {|i|
		var fn;
		var coefs = inDims.collect({
			(((prng.next(phi)-0.5)*pi).atan/(inDims.sqrt)).clip2(10.0)
		});
		combinercoefs[i] = coefs;
		fn = {
			(this.inParams * coefs).sum;
		};
		^fn;
	}
	phi_ {|val|
		phi = val;
		this.genCombiners;
	}
	abase_{|val|
		abase = val;
		prng = PSSawMapGenerator.new(abase,astep,cbase,cstep);
		this.genCombiners;
	}
	astep_{|val|
		astep = val;
		prng = PSSawMapGenerator.new(abase,astep,cbase,cstep);
		this.genCombiners;
	}
	cbase_{|val|
		cbase = val;
		prng = PSSawMapGenerator.new(abase,astep,cbase,cstep);
		this.genCombiners;
	}
	cstep_{|val|
		cstep = val;
		prng = PSSawMapGenerator.new(abase,astep,cbase,cstep);
		this.genCombiners;
	}
	set{|i, val, lo=(-1.0), hi=1.0|
		inParams[i] = val.linlin(lo.asFloat, hi.asFloat, -1.0, 1.0);
	}
	curve {|val|
		^1/(1+val.neg.exp);
	}
	value {
		outParams = combiners.collect({|combiner|
			this.curve(combiner.value * gain)
		});
		^outParams;
	}
}
/*
PSParammapper {
	metaparams = FloatArray.fill(7,0.5);
	params = FloatArray.fill(32,0.5);
	pitchrollyawaccel = FloatArray.fill(4,0.5);

	paramUpdaters = List.new;
		paramWatcher = Routine({|newinval|
		var lastposttime=0.0, delta=0.0;
		inf.do({|ix|
			state.paramDirty.if({
				state.paramDirty = false;
				(delta>10.0).if({
					[\wii_updating,state.metaparams, newinval, delta].postln;
					lastposttime = newinval;
				});
				state.params = state.paramMap.value(state.metaparams);
				state.paramUpdaters.do({|fn, i|
					fn.value(state.params[i]);
				});
			});
			newinval = 0.02.yield;
			delta = newinval-lastposttime;
		});
	}).play;
	CmdPeriod.doOnce { paramWatcher.free };

}
*/