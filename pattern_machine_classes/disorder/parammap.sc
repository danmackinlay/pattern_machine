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
PSRandomIndexedProjection {
	var <aVals;
	var <cVals;
	var <parentPrng;
	*new{|n=4, seed=3.7|
		var aVals, cVals, parentPRNG ;
		parentPRNG = LinCongRNG(seed:seed);
		aVals = parentPRNG.nextN(n)*8 +5.0001.postln;
		cVals = parentPRNG.nextN(n)*8 +0.0001.postln;
		^super.newCopyArgs(aVals, cVals);
	}
	value {|subSeed|
		^((aVals*subSeed)+cVals)%1
	}
}

PSRandomMap {
	var <inDims;
	var <outDims;
	var <projGenerator;
	var <phi;
	var <transformMat;
	var <seed;
	*new{|inDims=2, outDims=5, phi=1.1, seed=3.7|
		^super.newCopyArgs(
			inDims,
			outDims,
		).seed_(seed).phi_(phi);
	}
	seed_{|newSeed|
		seed = newSeed;
		projGenerator = PSRandomIndexedProjection(inDims*outDims, seed);
	}
	phi_ {|newPhi|
		phi = newPhi;
		// probably could rescale to adjust variance here.
		// Use Gaussian coef distribution because rotation-invariant
		// Could take other dists; there's nothing magic about rotation invariance
		transformMat = Matrix.withFlatArray(
			inDims, outDims, 
			PSInvPhi(projGenerator.value(phi).asFloatArray/(inDims.sqrt))
		);
	}
	value{|inParams|
		//TODO: optimise out the Matrix library here, which is not all that great codewise
		//full of halts and inconsistent w/rt permission and forgiveness
		var paramMat = Matrix.withFlatArray(1, inDims, PSInvPhi(inParams.asFloatArray));
		^PSPhi((paramMat*transformMat).asFlatArray);
	}
}
