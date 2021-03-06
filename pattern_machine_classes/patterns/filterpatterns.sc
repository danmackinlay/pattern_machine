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

			inevent = stream.next(event);
			inevent ?? { ^event  }; //exit on nil
			inevent = inevent.asEvent;
			cleanup.update(inevent);
			delta = inevent.delta;
			nextElapsed = elapsed + delta;
		}
	}
}
//Handy abstraction to alter events with a lazy-evaluated function executed in the current event, with a state ref.
PStateEnvirfunc  {
	*new {
		arg nextFunc, resetFunc, state;
		^Pfunc({
			arg ev;
			ev.make({nextFunc.value(state)});
		}, {
			arg ev;
			ev.make({resetFunc.value(state)});
		});
	}
}