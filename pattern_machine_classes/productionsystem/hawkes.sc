PHawkes : Pattern {
	var <>nChildren; // eta param; keep it less than 1 if you know what's good for you.
	var <>wait; //when to spawn
	var <>mark; //process marks
	var <>accum; // whether marks are cumulative
	var <>startMark; //cumulative marks start from here
	var <>protoEvent; //proto event. Necessary?
	*new { arg nChildren, wait, mark, accum=false, startMark, protoEvent;
		//normalise here?
		^super.new.nChildren_(nChildren
			).wait_(wait
			).mark_(mark
			).accum_(accum
			).startMark_(startMark
			).protoEvent_(protoEvent ?? Event.default
		).initPHawkes;
	}
	initPHawkes {
		
	}
	
	asStream {
		^Routine({ | ev | this.embedInStream(ev) })
	}
	storeArgs { ^[nChildren, wait, mark, accum, startMark]}

	asHawkesStream {
		^HawkesStream(nChildren,
			wait,
			mark,
			accum,
			startMark,
		)
	}

	embedInStream { | inevent, cleanup |
		^this.asHawkesStream.embedInStream(
			inevent,
			cleanup ?? { EventStreamCleanup.new }
		);
	}
}

HawkesStream  {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	var <>protoEvent;
	var <>priorityQ;
	var <>now;
	var <>event;

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
		var nextEvent;
		priorityQ = PriorityQueue.new;
		now = 0;
		nextEvent = this.next(event, startMark);
		priorityQ.put(now, nextEvent);
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
		event = inevent;
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
