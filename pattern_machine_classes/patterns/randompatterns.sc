PMarkovChain : Pattern {
	/* Ignores input; outputs a Markov chain of 1st order,
	which is the only non-bullshit order.
	*/
	var <>probs; //transition matrix
	var <>halt; //stop value. defaults to nil, which never happens
	var <>expressions; //how are our Markov states expressed? defaults to state number
	var <>initState; //inital state 
	var <>state; //current state
	var <stateidx; //index numbers
	*new { arg probs, halt, expressions, initState=0;
		//normalise here?
		^super.newCopyArgs(
			probs.collect({|row| row.normalizeSum}),
			halt,
			expressions,
			initState
		).initPMarkov;
	}
	//create random markov chain.
	//If I were a wanker, I might parameterise in terms of entropy rate, but something more ad hoc will do I think.
	// could also choose uniform probs
	// could go for sparsity. wevs.
	*auto {
		arg nstates=4, disorder=0.25, stride=1, ordertype=\static, halt, initState=\rand, expressions;
		var order, probs;
		//If we give nstates but set expressions to special \unit, they are mapped onto 0,1
		(expressions==\unit).if({
			expressions = Array.series(nstates)/(nstates-1);
		});
		//if we give expressions then nstates can be implicit.
		expressions.notNil.if({
			nstates = expressions.size;
		});
		probs = nstates.collect({
			arg rownum;
			var row = 0.dup(nstates);
			
			//Some basic most-common-transition-types
			ordertype.switch(
				\static, {row[rownum] = 1},
				\inc, {row[(rownum+stride)%nstates] = 1},
				\drunk, {
					row[(rownum+stride)%nstates] = 1/2;
					row[(rownum-stride)%nstates] = 1/2;},
				{"unknown ordertype '%'".format(ordertype.asString).throw}
			);
			row * (1-disorder) + disorder;
		});
		//initstate can be a scalar, a function or a special \rand symbol, meaning "uniform"
		(initState==\rand).if({
			initState = {nstates.rand};
		});
		initState.isNil.if({
			initState = 0;
		});
		^this.new(probs, halt, expressions, initState);
	}
	randomize {|seed, randomness=0.25, shuffleness=1|
		var prevRndState;
		seed.notNil.if({
			prevRndState = thisThread.randData;
			thisThread.randSeed = seed;
		});
		//under construction
		seed.notNil.if({
			thisThread.randData = prevRndState;
		});
	}
	initPMarkov {
		stateidx = Array.series(probs.size);
		expressions.isNil.if({
			expressions = stateidx;
		});
	}
	storeArgs { ^[probs, halt, expressions, initState, state]}

	printOn { |stream|
		this.storeOn(stream)
	}
	/*
	TODO: generate my own Routine and just pull values from this
	  when embedding;
	Otherwise not much point exposing a writeable state.
	OTOH since RNGs are thread- and hence Routine-local,
	  and they don't seem to inherit especially intuitively,
	  this breaks seedability.
	*/
	embedInStream { arg inval;
		state = initState.value;
		//we more or less ignore the input value.
		({state != halt}).while({
			state = stateidx.wchoose(probs[state]);
			inval = expressions[state].embedInStream(inval);
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

