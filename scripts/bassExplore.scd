//We create a an FM synth with very open parameters, and infer a manifold of optimal sickness.

//This has 2 phases.

//First, a convenient way of finding optimal parameters; This will prolly be through some random matrix projection.

// Second infer a hyperplane (or even just a simplex?) defined by this and interpolate it.

// If I chose adroit marginal distributions, could I skip the second step entirely? Perhaps. That leads to a weird meta-optimisation propethy though - what are appropriate mappings? Also what gives me a PRNGs with continuous dependence on seed? and what is an appropriate scaling for the amtrix

//Produces an RNG that returns a vector of uncorrelated pseudo-randoms indexed by a scalar
/*~randomPRNGFactory{|n, seed|
	var aVals, cVals, mVals;

};*/

LinCongRNG(

SynthDef.new(\fmraw, {|freq,
	harmonicfreqs,
	ringModAmp,
	fModAmp,
	attacks,
	decays,
	sustains,
	releases,
	pans,
	trigger|
	var oscs;
}).add;


SynthDef.new(\fmapped, {|freq,
	paramMap,
	mapBus,
	trigger|
}).add;
QtImage