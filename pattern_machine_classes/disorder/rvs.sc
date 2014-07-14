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
			inval = (0.0.rrand(1.0).log.neg/lambda).yield; //supposedly excludes endpoints
		});
		^inval;
	}
}