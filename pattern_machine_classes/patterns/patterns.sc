//Handy constructors for Patterns that I would like to be a little tidier.
PSwrand {
	*new {|weightedList, repeats=1|
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		^Pwrand.new(expressions, weights, repeats);
	}
}
P1bind {
	//P-one-bind embeds the arguments as a single event in the stream ONCE
	//(events embed perpetually per default.)
	//note events with better defaults, or an event subclass,
	// might be able to avoid that
	// Shouldn't this be EmbedOnce, or OneShot?
	*new { arg ... pairs;
		^Pfin(1, Pbind(*pairs))
	}
}
P1Rest {
	//P-one-Rest embeds the arguments as a single event in the stream ONCE
	//see P1bind for disclaimers.
	*new { arg dur;
		^Pfin(1, Rest(dur))
	}
}

PContext : Pattern {
	/* Looks up a key in an external state collection
	(
		~state = (a:1);
		~str =Pbind(\delta, PContext(~state, \a)).trace.play;
	)
	*/
	var <>state; 
	var <>key; // Func is evaluated for each next state
	*new { arg state, key, default;
		^super.newCopyArgs(state, key, default)
	}
	storeArgs { ^[state, key, default] }
	asStream {
		^FuncStream.new({state.at(key) ? default})
	}
}
