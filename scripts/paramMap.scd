/*
We create pattern with very open parameters, and infer a manifold of optimal sickness.

This has 2 phases.

First, a convenient way of finding optimal parameters; This will prolly be through some random matrix projection.

Second infer a hyperplane (or even just a simplex?) defined by this and interpolate it.

If I chose adroit marginal distributions, could I skip the second step
entirely? Perhaps. That leads to a weird meta-optimisation problem though -
what are *appropriate* mappings?
Also, what gives me PRNGs with continuous dependence on seed?
And what is an appropriate scaling for the matrix?
To check: do we have extreme enough param values ATM?
*/

//Produces an RNG that returns a vector of uncorrelated pseudo-randoms indexed by a scalar
~randomPRNGFactory={|n=4, seed=3.7|
	var aVals, cVals, seedVals, parentPRNG, transformMatrix;
	parentPRNG = LinCongRNG(seed:seed);
	aVals = parentPRNG.nextN(n)*8 +5.0001.postln;
	cVals = parentPRNG.nextN(n)*8 +0.0001.postln;
	seedVals = parentPRNG.nextN(n) + 0.00001.postln;
	{|innerSeed|
		((aVals*innerSeed)+cVals)%1
	};
};
~inDims = 2;
~outDims = 5;
~r=~randomPRNGFactory.(~inDims*~outDims);
// probably could rescale to adjust variance here.
// Use Gaussian coeff distribution because rotation-invariant
// Could take other dists.
~transformMat = Matrix.withFlatArray(~inDims, ~outDims, PSInvPhi(~r.(1.1)).asFloatArray/(~inDims.sqrt));
~map = {|...params|
	var paramMat=Matrix.withFlatArray(1,2,PSInvPhi(params)).postln;
	//NB map here could well be logit
	PSPhi((paramMat*~transformMat).asFlatArray);
};
~map.(0.001,0.9);
~map.(0.021,0.9);
