/*
 * Boilerplate for various RVs-as-patterns
 */

//Exponential RV (Rate parameterisation)
PexpR : Pattern {
	var <>lambda, <>length;
	*new{arg lambda = 1, length = inf;
		^super.newCopyArgs(lambda, length);
	}
	storeArgs{ ^[lambda, length] }
	embedInStream{ arg inval;
		var lambdaStr = lambda.asStream;
		length.value(inval).do({
			var inlambda = lambdaStr.next(inval);
			inlambda ?? {^inval};
			inval = inlambda.expR.yield; 
		});
		^inval;
	}
}

//Exponential RV (Scale parameterisation)
PexpS : Pattern {
	var <>beta, <>length;
	*new{arg beta = 1, length = inf;
		^super.newCopyArgs(beta, length);
	}
	storeArgs{ ^[beta, length] }
	embedInStream{ arg inval;
		var betaStr = beta.asStream;
		length.value(inval).do({
			var inbeta = betaStr.next(inval);
			inbeta ?? {^inval};
			inval = inbeta.expS.yield; 
		});
		^inval;
	}
}

PGeomRV {
	*newFromCluster {
		arg m, length=inf;
		^this.newFromMean(1-(m.reciprocal), length);
	}
	*newFromP {
		arg p, length=inf;
		^PGeomP(p, length);
	}
	*newFromMean {
		arg mean, length=inf;
		^PGeomM(mean, length)
	}
}

//Geometric RV (prob parameterisation)
PGeomP : Pattern {
	var <>p, <>length;
	*new{arg p = 1, length = inf;
		^super.newCopyArgs(p, length);
	}
	storeArgs{ ^[p, length] }
	embedInStream{ arg inval;
		var pStr = p.asStream;
		length.value(inval).do({
			var inp = pStr.next(inval);
			inp ?? {^inval};
			inval = p.geomP.yield;
		});
		^inval;
	}
}

//Geometric RV (mean parameterisation)
PGeomM : Pattern {
	var <>mean, <>length;
	*new{arg mean = 1, length = inf;
		^super.newCopyArgs(mean, length);
	}
	storeArgs{ ^[mean, length] }
	embedInStream{ arg inval;
		var meanStr = mean.asStream;
		length.value(inval).do({
			var inmean = meanStr.next(inval);
			inval = inmean.geomM.yield;
		});
		^inval;
	}
}

