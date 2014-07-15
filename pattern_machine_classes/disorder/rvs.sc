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