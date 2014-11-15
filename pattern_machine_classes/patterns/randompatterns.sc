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
	var <>state; //current/inital state
	var <>expressions; //how are our Markov states expressed? defaults to state index number.
	var <stateidx;
	*new { arg probs, halt, state=0, expressions;
		//normalise here?
		^super.newCopyArgs(
			probs.collect({|row| row.normalizeSum}),
			halt,
			state,
			expressions
		).initPMarkov;
	}
	//create random markov chain.
	//If I were a wanker, I might parameterise in terms of entropy rate, but something more ad hoc will do I think.
	// could also choose uniform probs
	// could go for sparsity. wevs.
	*random {
		arg nstates=4, disorder=0.25, ordertype=\static, halt, state=0, expressions, seed;
		var order, probs, prevRndState;
		seed.notNil.if({
			prevRndState = thisThread.randData;
			thisThread.randSeed = seed;
		});
		//if we give expressions then nstates can be implicit.
		expressions.notNil.if({
			nstates = expressions.size;
		});
		order = Array.series(nstates);
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
		^this.new(probs, halt, state, expressions);
	}
	initPMarkov {
		stateidx = Array.series(probs.size);
		expressions.isNil.if({
			expressions = stateidx;
		});
	}
	storeArgs { ^[probs, halt, state, expressions]}
	embedInStream { arg inval;
		//we more or less ignore the input value.
		({state != halt}).while({
			state = stateidx.wchoose(probs[state]);
			inval = expressions[state].embedInStream(inval);
		});
		^inval;
	}
}

//emebed geometrically truncated input sequence
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
