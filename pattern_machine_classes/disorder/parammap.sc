/*
We create pattern with very open parameters, and infer a manifold of optimal sickness.

I'd like to do this in 2 different ways:

	* calculate a manifold that fits several desirable presets
	* generate random param manifolds/hyperplanes and interpolate

TODO: impose continuous sparseness
TODO: multiple set to avoid too many triggers
TODO: allow metaparammap to also allocate a param # automagically
TODO: make sure outputs are full range
TODO: plot values
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
	var <>paramDirty = true;
	
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
		paramDirty = true;
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
		paramDirty = true;
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
PSParamWatcher {
	var <metaParamMap;
	var <pollPeriod;
	var <updaterFns;
	var <watcher;
	var <active;
	var <all;
	*new {|metaParamMap, pollPeriod=0.05|
		^super.newCopyArgs(metaParamMap, pollPeriod).initPSParamWatcher;
	}
	initPSParamWatcher {
		updaterFns = Array.new(metaParamMap.outDims);
		active = IdentitySet.new(metaParamMap.outDims);
		all = IdentitySet.new(metaParamMap.outDims);
		watcher = Routine({|newinval|
			var lastposttime=0.0, delta=0.0;
			inf.do({|ix|
				metaParamMap.paramDirty.if({
					metaParamMap.paramDirty = false;
					active.do({|i|
						updaterFns[i].value(metaParamMap.outParams[i]);
					});
				});
				this.pollPeriod.yield;
			});
		}).play;
		CmdPeriod.doOnce { watcher.free };
	}
	addUpdater {|updater, i|
		i.isNil.if({
			i = all.size;
			updaterFns.add(nil);
		});
		updaterFns[i] = updater;
		all.add(i);
		active.add(i);
	}
	solo {|...args|
		active = IdentitySet.newFrom(args);
	}
	soloAndPing{|i|
		
	}
	tutti {
		active = all.copy;
	}
}
PSParamWatcherMIDI : PSParamWatcher {
	var <>midiout;
	
	*new {|metaParamMap, pollPeriod, midiout|
		^super.new(metaParamMap, pollPeriod
			).midiout_(midiout);
	}
	addMIDIUpdater {|chan, cc, i|
		var midifunc = {|val|
			[\pinging, chan, cc, val.linlin(0.0,1.0,0,127)].postln;
			midiout.control (chan:chan, ctlNum: cc, val: val.linlin(0.0,1.0,0,127));
		};
		this.addUpdater(midifunc, i);
	}
}
/*
plotter = Plotter(\anal);
plotter.minval_(-1);
plotter.maxval_(1);
state[\plotter] = plotter;
state[\plotterrout] = AppClock.play(
	Routine({
		{state[\plotter].notNil}.while({
			plotter.value = state[\anal];
			plotter.minval_(-1);
			plotter.maxval_(1);
			0.1.yield;
		})
	})
);
*/
