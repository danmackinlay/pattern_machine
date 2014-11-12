//Handy pseudopatterns for Patterns that I would like to be a little tidier.
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
	//events embed inconsistently
	// e.g. eternally repeating if you embed them in parallel, otherwise just once.
	// Note events with better defaults, or an event subclass,
	// might be able to do this better.
	// Shouldn't this be EmbedOnce, or OneShot?
	*new { arg ... pairs;
		^Pfin(1, Pbind(*pairs))
	}
}
P1event : Pattern {
	//P-one-EVENT embeds the arguments as a single event in the stream ONCE
	//see P1bind for disclaimers.
	var <>pattern, <>event;

	*new { arg pattern, event;
		^super.newCopyArgs(pattern, event ?? { Event.default });
	}
	storeArgs { ^[pattern, event] }
	embedInStream { arg inval;
		var outval;
		outval = pattern.asStream.next(event);
		if (outval.isNil) { ^inval };
		inval = outval.yield;
		^inval;
	}
}
P1Rest {
	//P-one-Rest embeds the arguments as a single rest event in the stream ONCE
	//see P1bind for disclaimers.
	*new { arg dur;
		^Pfin(1, Rest(dur))
	}
}

