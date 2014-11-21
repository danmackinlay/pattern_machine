/* Ignores input; outputs a Markov chain of 1st order,
which is the only non-bullshit order.

TODO allow a non-deterministic first step; 'tis traditional, and handy.
*/
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
	*random {
		arg nstates=4, disorder=0.25, ordertype=\static, halt, initState=\rand, expressions, seed;
		var order, probs, prevRndState;
		seed.notNil.if({
			prevRndState = thisThread.randData;
			thisThread.randSeed = seed;
		});
		//If we give nstates but set expressions to special \unit, they are mapped onto 0,1
		(expressions==\unit).if({
			expressions = Array.series(nstates)/(nstates-1);
		});
		//if we give expressions then nstates can be implicit.
		expressions.notNil.if({
			nstates = expressions.size;
		});
		order = Array.series(nstates);
		//Some basic most-common-transition-types
		ordertype.switch(
			\static, nil,
			\inc, {order = (order+1) % nstates},
			\chaos, {order = order.scramble},
			{"unknown ordertype '%'".format(ordertype.asString).throw}
		);
		probs = order.collect({
			arg dest, rownum;
			var disordered, ordered = 0.dup(nstates);
			ordered[dest] = 1;
			disordered = Array.rand(nstates, 0.0, 1.0);
			((disorder * disordered) + ((1-disorder) * ordered)).normalizeSum;
		});
		seed.notNil.if({
			thisThread.randData = prevRndState;
		});
		//initstate can be a scalar, a function or a special \rand symbol, meaning "boom"
		(initState==\rand).if({
			initState = {nstates.rand};
		});
		initState.isNil.if({
			initState = 0;
		});
		^this.new(probs, halt, expressions, initState);
	}
	initPMarkov {
		stateidx = Array.series(probs.size);
		expressions.isNil.if({
			expressions = stateidx;
		});
	}
	storeArgs { ^[probs, halt, expressions, initState, state]}
	//TODO generate my own routine and just pull values from this when embedding;
	//otherwise not much point exposing a writeable state.
	//OTOH since RNGs are thread- and hence routine-local, this breaks seedability
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

//embed geometrically truncated input sequence
PGeomN : FilterPattern {
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
