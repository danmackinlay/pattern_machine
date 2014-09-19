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
TODO: make optional index param the LAST param
*/

// Linear-congruential-like PRVG, that is, a pseudo-random vector generator.
// More *pseudo* than *random*
// Formally, a piecewise continuous map from R -> ([0,1]^n).
PSSawMapGenerator {
	*new{|abase=3.117111, astep=0.77733, cbase=0.23335, cstep=0.3347|
		^Routine({|phi=0.1|
			var a=abase;
			var c=cbase;
			inf.do({
				phi = ((phi*a)+c).fold(0.0,1.0).yield;
				a=a+astep;
				c=c+cstep;
			});
		});
	}

}

// Internally uses symmetric variables [-1,1] because they are more convenient than [0,1]
PSMetaParamMap {
	var <inDims;
	var <outDims;
	var <gain;
	var <phi;
	var <abase;
	var <astep;
	var <cbase;
	var <cstep;
	var <>spreadfactor;
	var <combiners;
	var <prng;
	var <inParams;
	var <outParams;
	var <combinercoefs;//just for debugging
	var <paramDirty = true;
	var <plotter, <plotupdater;

	*new{|inDims=3,
		outDims=5,
		gain=1.0,
		phi=0.1,
		abase=3.117111,
		astep=0.77733,
		cbase=0.23335,
		cstep=0.334,
		spreadfactor=1.1|
		^super.newCopyArgs(
			inDims,
			outDims,
			gain,
			phi,
			abase, astep, cbase, cstep,
			spreadfactor.asFloat,
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
		//generate actual coefs; could be tidier
		var fn;
		//Generate coeffs by a Cauchy dist; why not?
		var coefs = inDims.collect({
			(((prng.next(phi)-0.5)*pi).tan/(inDims.sqrt)).clip2(10.0)
		});
		combinercoefs[i] = coefs;
		fn = {
			this.spread(
				this.curve((this.inParams * coefs).sum * gain)
			);
		};
		^fn;
	}
	gain_ {|val|
		gain = val;
		this.genCombiners;
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
		//logistic R->(0,1)
		^(1/(1+val.neg.exp));
	}
	spread{|val|
		//spread sigmoid ONTO [0,1]
		^((val-0.5)*spreadfactor+0.5).clip(0.0,1.0);
	}
	next {
		paramDirty.if({
			outParams = combiners.collect(_.value);
			paramDirty = false;
		});
		^outParams;
	}
	plot {|name="metaparams", bounds, parent, plotrate=0.1|
		plotter ?? {this.free;};
		plotter = Plotter(name, bounds, parent);
		plotter.minval_(0);
		plotter.maxval_(1);
		plotter.plotMode_(\steps);
		plotupdater = AppClock.play(
			Routine({
				{plotter.notNil}.while({
					plotter.value = outParams;
					plotter.minval_(0);
					plotter.maxval_(1);
					plotrate.yield;
				})
			})
		);
	}
	free {
		plotter.free;
		plotter = nil;
		plotupdater.free;
		plotupdater = nil;
	}
}
// As above, but first inDims params are near-identity
PSSemiOrderlyMetaParamMap : PSMetaParamMap {
	genCombiner {|i|
		var out; //debugging var
		//[\i, i].postln;
		(i<inDims).if({
			var fn, coefs = Array.fill(inDims,0.0);
			//cosmetic coefficient tracking; not really reflective here
			coefs[i] = 1.0;
			combinercoefs[i] = coefs;
			fn = {
				(this.inParams[i]*spreadfactor).linlin(-1.0, 1.0, 0.0, 1.0);
			};
			//combinercoefs[i].postcs;
			^fn;
		}, {
			out=super.genCombiner(i);
			//combinercoefs[i].postcs;
			^out;
		});
	}
}
PSParamForwarder {
	var <metaParamMap;
	var <pollPeriod;
	var <updaterFns;
	var <watcher;
	var <active;
	var <all;
	var <params;
	//optional midi destination
	var <>defaultMidiout;

	*new {|metaParamMap, pollPeriod=0.05, midiout|
		^super.newCopyArgs(
			metaParamMap, pollPeriod
		).initPSParamForwarder.defaultMidiout_(midiout);
	}
	initPSParamForwarder {
		updaterFns = Array.fill(metaParamMap.outDims);
		active = IdentitySet.new(metaParamMap.outDims);
		all = IdentitySet.new(metaParamMap.outDims);
		watcher = Routine({|newinval|
			inf.do({|ix|
				params = metaParamMap.next;
				active.do({|i|
					this.transmit(i);
				});
				this.pollPeriod.yield;
			});
		}).play;
	}
	free {
		watcher.free;
	}
	//send some data down the correct pipe for this param
	transmit {|i|
		updaterFns[i].value(params[i]);
	}
	solo {|...args|
		active = IdentitySet.newFrom(args);
	}
	mute {|...args|
		active = active - IdentitySet.newFrom(args);
	}
	muteAll {|...args|
		active = IdentitySet.new;
	}
	// send whatever data down the pipe; mostly useful for MIDI/OSC learn
	ping {
		active.do({|i|
			this.transmit(i);
		});
	}
	soloAndPing{|i|
		active = IdentitySet.newFrom([i]);
		this.ping;
	}
	tutti {
		active = all.copy;
	}
	addUpdater {|updater, i|
		i.isNil.if({
			i = all.size;
			updaterFns.add({});
		});
		updaterFns[i] = updater;
		all.add(i);
		active.add(i);
	}
	//shortcut for MIDI-specific mappings
	//maybe worth it for Bus and OSC dests too?
	addMIDICCUpdater {|chan=0, cc=0, i=nil, mididest=nil|
		var midifunc = {|val|
			//[\pinging, chan, cc, val.linlin(0.0,1.0,0,127)].postln;
			(mididest ? defaultMidiout).control (
				chan:chan,
				ctlNum: cc,
				val: val.linlin(0.0,1.0,0,127).asInt
			);
		};
		this.addUpdater(midifunc, i);
	}
}
