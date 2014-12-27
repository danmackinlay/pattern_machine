PEndo : Pattern {
	var <>nChildren; // eta param; keep it less than 1 if you know what's good for you.
	var <>wait; //when to spawn
	var <>mark; //process marks
	var <>accum; // whether marks are cumulative
	var <>startMark; //cumulative marks start from here
	var <>protoEvent; //proto event. Do I actually USE this?
	// IF I do, SHOULD I?
	*new { arg nChildren,
			wait,
			mark,
			accum=false,
			startMark,
			protoEvent;
		//normalise here?
		^super.new.nChildren_(nChildren
			).wait_(wait
			).mark_(mark
			).accum_(accum
			).startMark_(startMark
			).protoEvent_(protoEvent ?? Event.default
		).initPEndo;
	}
	initPEndo {
		
	}
	
	asStream {
		^Routine({ | ev | this.embedInStream(ev) })
	}
	storeArgs { ^[nChildren, wait, mark, accum, startMark, protoEvent]}

	asEndoStream {
		^EndoStream(nChildren,
			wait,
			mark,
			accum,
			startMark,
			protoEvent,
		)
	}

	embedInStream { | inevent, cleanup |
		^this.asEndoStream.embedInStream(
			inevent,
			cleanup ?? { EventStreamCleanup.new }
		);
	}
}


EndoStream {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	var <>protoEvent;
	var <>priorityQ;
	var <>now;

	*new { |nChildren, wait, mark, accum, startMark, protoEvent|
		^super.new.nChildren_(nChildren.asStream
			).wait_(wait.asStream
			).mark_(mark.asStream
			).accum_(accum
			).startMark_(startMark
			).protoEvent_(protoEvent ?? Event.default
		).init;
	}

	init { 
		priorityQ = PriorityQueue.new;
		now = 0;
	}
	next { |event, startMark|
		var nextNChildren = nChildren.next(event);
		var nextWait = wait.next(event);
		var nextMark = startMark ?? {mark.next(event)};
		((nextWait.notNil).and(nextMark.notNil).and(nextNChildren.notNil)).if({
			^(
				nChildren: nextNChildren,
				wait: nextWait,
				mark: nextMark
			)
		}, {
			^nil
		});
	}

	embedInStream { | inevent, cleanup|
		var outevent, event, nexttime;
		event = this.next(inevent, startMark);
		event.notNil.if({
			priorityQ.put(now, event);
		});
		cleanup ?? { cleanup = EventStreamCleanup.new };

		while({
			priorityQ.notEmpty
		},{
			outevent = priorityQ.pop.asEvent;
			outevent.isNil.if({
				//out event was nil, so we are done. go home.
				priorityQ.clear;
				^cleanup.exit(event);
			}, {
				//outevent  existed, so we emit it and queue its children
				\nonempty.postln;
				outevent.postcs;
				cleanup.update(outevent);
				// requeue stream
				outevent.nChildren.do({
					var nextEvent = this.next(event);
					nextEvent.notNil.if({
						accum.if({
							nextEvent.mark_((outevent.mark) + (nextEvent.mark));
						});
						priorityQ.put(now + (nextEvent.wait), nextEvent);
					});
				});
				nexttime = priorityQ.topPriority ? now;
				outevent.put(\delta, nexttime - now);
				event = outevent.yield;
				now = nexttime;
			});
		});
		^event;
	}
}

PEndoExo : FilterPattern {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	*new { arg pattern, 
			nChildren,
			wait,
			mark,
			accum=false,
			startMark;
		^super.new(pattern).nChildren_(nChildren
			).wait_(wait
			).mark_(mark
			).accum_(accum
			).startMark_(startMark
		).initPEndoExo;
	}
	initPEndoExo {
		
	}
	asStream {
		^Routine({ | ev | this.embedInStream(ev) })
	}
	storeArgs { ^[nChildren, wait, mark, accum, startMark, pattern]}

	asEndoExoStream {
		^EndoExoStream(nChildren,
			wait,
			mark,
			accum,
			startMark,
			pattern,
		)
	}

	embedInStream { | inevent, cleanup |
		^this.asEndoExoStream.embedInStream(
			inevent,
			cleanup ?? { EventStreamCleanup.new }
		);
	}
}

EndoExoStream {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	var <>stream;
	var <>priorityQ;
	var <>now;
	var <>stream;
	
	*new { |nChildren, wait, mark, accum, startMark, pattern|
		^super.new.nChildren_(nChildren.asStream
			).wait_(wait.asStream
			).mark_(mark.asStream
			).accum_(accum
			).startMark_(startMark
			).stream_(pattern.asStream
		).init;
	}

	init { 
		var nextEvent;
		priorityQ = PriorityQueue.new;
		now = 0;
	}
	//returns next event even stitched from incoming streams
	//sub events will be synthesized from this
	next { |event, startMark|
		var nextEvent = stream.next(event);
		var nextNChildren = nChildren.next(event);
		var nextWait = wait.next(event);
		var nextMark = startMark ?? {mark.next(event)};
		((nextEvent.notNil).and(nextWait.notNil).and(nextMark.notNil).and(nextNChildren.notNil)).if({
			nextEvent = nextEvent.copy.putAll(
				nChildren: nextNChildren,
				wait: nextWait,
				mark: nextMark
			);
			\next.postln;
			nextEvent.postcs;
			^nextEvent;
		}, {
			^nil
		});
	}

	embedInStream { | inevent, cleanup|
		var outevent, event, nexttime, nextEvent;
		event = this.next(inevent, startMark);
		event.notNil.if({
			priorityQ.put(now, event);
		});
		cleanup ?? { cleanup = EventStreamCleanup.new };
		\step1.postln;
		while({
			priorityQ.notEmpty
		},{
			\step2.postln;
			nextEvent = this.next(event);
			nextEvent.notNil.if({
				priorityQ.put(now + (nextEvent.wait), nextEvent)
			});
			outevent = priorityQ.pop.asEvent;
			\step3.postln;
			outevent.postcs;
			outevent.isNil.if({
				//out event was nil, so we are done. go home.
				priorityQ.clear;
				^cleanup.exit(event);
			}, {
				//outevent  existed, so we emit it and queue its children
				\nonempty.postln;
				outevent.postcs;
				cleanup.update(outevent);
				// requeue stream
				outevent.nChildren.do({
					nextEvent = this.next(event);
					nextEvent.notNil.if({
						accum.if({
							nextEvent.mark_((outevent.mark) + (nextEvent.mark));
						});
						priorityQ.put(now + (nextEvent.wait), nextEvent);
					});
				});
				nexttime = priorityQ.topPriority ? now;
				outevent.put(\delta, nexttime - now);
				event = outevent.yield;
				now = nexttime;
			});
		});
		^event;
	}
}