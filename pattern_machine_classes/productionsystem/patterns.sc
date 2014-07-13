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
Pobind {
	//P-one-bind embeds the arguments as a single event in the stream ONCE
	//(events embed perpetually per default.)
	//note events with better defaults, or an event subclass,
	// might be able to avoid that
	*new { arg ... pairs;
		^Pfin(1, Pbind(*pairs))
	}
}
PoRest {
	//P-one-Rest embeds the arguments as a single event in the stream ONCE
	//(events embed perpetually per default.)
	//note events with better defaults, or an event subclass,
	// might be able to avoid that
	*new { arg dur;
		^Pfin(1, Rest(dur))
	}
}
Pdropdur : FilterPattern {
	var <>start, <>tolerance;
	*new { arg start, pattern, tolerance = 0.001;
		^super.new(pattern).start_(start).tolerance_(tolerance)
	}
	storeArgs { ^[start,pattern,tolerance] }
	//asStream { | cleanup| ^Routine({ arg inval; this.embedInStream(inval, cleanup) }) }

	embedInStream { arg event;
		var item, delta, elapsed = 0.0, nextElapsed = 0.0, inevent,
			localstart = start.value(event);
		var stream = pattern.asStream;
		//scroll through the skippable part
		{nextElapsed.roundDown(tolerance) < localstart}.while({
			inevent = stream.next(event).asEvent ?? { ^event };
			delta = inevent.delta;
			nextElapsed = nextElapsed + delta;
		});
		//handle an offset-rest.
		event = Event.silent(nextElapsed-localstart).yield;
		loop {
			inevent = stream.next(event).asEvent ?? { ^event };
			event = inevent.yield;
		}
	}
}
//like Pfindur, but can also skip the start
//Does this handle end padding correctly like Psync?
Pcutdur : FilterPattern {
	var <>start,<>dur,<>tolerance;
	*new { arg start, dur, pattern, tolerance = 0.001;
		^super.new(pattern).start_(start).dur_(dur).tolerance_(tolerance)
	}
	guiClass { ^PcutdurGui }
	
	storeArgs { ^[start,dur,pattern,tolerance] }
	asStream { | cleanup| ^Routine({ arg inval; this.embedInStream(inval, cleanup) }) }

	embedInStream { arg event, cleanup;
		var item, delta, elapsed = 0.0, nextElapsed = 0.0, inevent,
			localstart = start.value(event),
			localdur = dur.value(event);
		var stream = pattern.asStream;

		cleanup ?? { cleanup = EventStreamCleanup.new };

		//scroll through the skippable part
		{nextElapsed.roundDown(tolerance) < localstart}.while({
			inevent = stream.next(event).asEvent ?? { ^event };
			delta = inevent.delta;
			nextElapsed = nextElapsed + delta;
		});
		//how long until the next event?
		delta = nextElapsed-localstart;
		//handle an offset-rest
		inevent = Event.silent(delta);
		cleanup.update(inevent);

		// reset all counters for the next duration count.
		nextElapsed = delta;
		elapsed  = 0.0;

		loop {
			if (nextElapsed.roundUp(tolerance) >= localdur) {
				// must always copy an event before altering it.
				// fix delta time and yield to play the event.
				inevent = inevent.copy.put(\delta, localdur - elapsed).yield;
				^cleanup.exit(inevent);
			};

			elapsed = nextElapsed;
			event = inevent.yield;

			inevent = stream.next(event).asEvent ?? { ^event };
			cleanup.update(inevent);
			delta = inevent.delta;
			nextElapsed = elapsed + delta;
		}
	}
}