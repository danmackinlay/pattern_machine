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

//embed a geometric number of times
PGeomRepP : FilterPattern {
	var <>prob;
	
	*new { arg pattern, prob;
		//normalise here?
		^super.newCopyArgs(pattern, prob);
	}
	storeArgs { ^[pattern, prob]}
	embedInStream { 
		arg origin;
		var next, in, stream, probStream;
		//[\prob, prob].postcs;
		//[\origin, origin].postcs;
		in = origin;
		stream = pattern.asStream;
		probStream = prob.asStream;
		{(probStream.next(in) ? 0.0).coin}.while({
			next = stream.next(in);
			//[\next, next].postcs;
			//in ?? { ^origin  }; //exit on nil
			in = next.yield;
			//[\in, in].postcs;
		}, {
			^origin;
		});
		^origin;
	}
}

PGeomRepM : FilterPattern {
	var <>mean;
	
	*new { arg pattern, mean;
		//normalise here?
		^super.newCopyArgs(pattern, mean);
	}
	storeArgs { ^[pattern, mean]}
	embedInStream { 
		arg origin;
		var next, in, stream, meanStream, nextMean;
		//[\mean, mean].postcs;
		//[\origin, origin].postcs;
		in = origin;
		stream = pattern.asStream;
		meanStream = mean.asStream;
		nextMean = meanStream.next(in) ? 0;
		{(nextMean/(1.0+nextMean)).coin}.while({
			next = stream.next(in);
			nextMean = meanStream.next(in) ? 0;
			//[\next, next].postcs;
			//in ?? { ^origin  }; //exit on nil
			in = next.yield;
			//[\in, in].postcs;
		}, {
			^origin;
		});
		^origin;
	}
}


