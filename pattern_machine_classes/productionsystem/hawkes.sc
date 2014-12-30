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

PEndoExo : Pattern {
	var <>exoPattern;
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	*new { arg exoPattern, 
			nChildren,
			wait,
			mark,
			accum=false,
			startMark;
		^super.new.exoPattern_(exoPattern
			).nChildren_(nChildren
			).wait_(wait
			).mark_(mark
			).accum_(accum
			).startMark_(startMark
		).initPEndoExo;
	}
	initPEndoExo {
		
	}
	storeArgs { ^[exoPattern, nChildren, wait, mark, accum, startMark]}

	asStream {
		^this.asEndoExoStream
	}

	asEndoExoStream {
		^EndoExoStream.new(
			nChildren,
			wait,
			mark,
			accum,
			startMark,
			exoPattern,
		)
	}
}

EndoExoStream : Stream {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>startMark;
	var <>priorityQ;
	var <>now;
	var <>event;
	var <>exoStream;
	
	*new { |nChildren, wait, mark, accum, startMark, exoPattern|
		^super.new.nChildren_(nChildren.asStream
			).wait_(wait.asStream
			).mark_(mark.asStream
			).accum_(accum
			).startMark_(startMark
			).exoStream_(exoPattern.asStream
		).init;
	}

	init { 
		var nextEvent;
		priorityQ = PriorityQueue.new;
		now = 0;
	}
	next { |event, startMark|
		var nextEv = exoStream.next(event);
		var nextNChildren = nChildren.next(event);
		var nextWait = wait.next(event);
		var nextMark = startMark ?? {mark.next(event)};
		\extranexty.postln;
		[\event, event].postcs;
		[\startMark, startMark].postcs;
		[\exoStream, exoStream].postcs;
		[\nextEv, nextEv].postcs;
		[\nextNChildren, nextNChildren].postcs;
		[\nextWait, nextWait].postcs;
		[\nextMark, nextMark].postcs;
		((nextEv.notNil).and(nextWait.notNil).and(nextMark.notNil).and(nextNChildren.notNil)).if({
			^nextEv.copy.putAll((
				nChildren: nextNChildren,
				wait: nextWait,
				mark: nextMark
			))
		}, {
			^nil
		});
	}

	asStream {
		^Routine({ | ev | this.embedInStream(ev) })
	}
	
	embedInStream { | inevent, cleanup|
		var outevent, event, nexttime, nextEvent;
		[\inny1, inevent].postcs;
		
		event = this.next(inevent, startMark);
		event.notNil.if({
			priorityQ.put(now, event);
		});
		
		cleanup ?? { cleanup = EventStreamCleanup.new };
		[\inny2, event].postcs;
		
		while({
			priorityQ.notEmpty
		},{
			nextEvent = this.next(event);
			\nexty.postln;
			nextEvent.postcs;
			
			nextEvent.notNil.if({
				priorityQ.put(now + (nextEvent.wait), nextEvent)
			});
			outevent = priorityQ.pop.asEvent;
			outevent.isNil.if({
				\empty.postln;
				outevent.postcs;
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