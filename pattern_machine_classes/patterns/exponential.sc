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
			inval = (0.0.rrand(1.0).log.neg/inlambda).yield; //supposedly excludes endpoints
		});
		^inval;
	}
}

//Exponential RV (Scale parameterisation)
Pexp : Pattern {
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
			inval = (0.0.rrand(1.0).log.neg*inbeta).yield; 
		});
		^inval;
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
			inval = (0.0.rrand(1.0).log.neg/((1-inp).log.neg)).yield;
		});
		^inval;
	}
}

//embed a geometric number of times
PGeomRep : FilterPattern {
	var <>successProb;
	
	*new { arg pattern, successProb;
		//normalise here?
		^super.newCopyArgs(pattern, successProb);
	}
	storeArgs { ^[pattern, successProb]}
	embedInStream { 
		arg origin;
		var next, in, stream;
		//[\successProb, successProb].postcs;
		//[\origin, origin].postcs;
		in = origin;
		stream = pattern.asStream;
		{successProb.coin}.while({
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
