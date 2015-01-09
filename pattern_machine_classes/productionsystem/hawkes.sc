//Hawkes process in SC
//TODO: manage total # of notes at near criticality

PEndoExo : Pattern {
	var <>exoPattern;
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	
	*new { arg exoPattern, 
			nChildren,
			wait,
			mark,
			accum=false;
		^super.new.exoPattern_(exoPattern ? Pn(Event.default,1)
			).nChildren_(nChildren
			).wait_(wait
			).mark_(mark
			).accum_(accum
		).initPEndoExo;
	}
	initPEndoExo {
		
	}
	storeArgs { ^[exoPattern, nChildren, wait, mark, accum]}

	asStream {
		^Routine({ | ev | this.asEndoExoStream.embedInStream(ev) })
	}

	asEndoExoStream {
		^EndoExoStream.new(
			nChildren,
			wait,
			mark,
			accum,
			exoPattern,
		)
	}
}

EndoExoStream  {
	var <>nChildren;
	var <>wait;
	var <>mark;
	var <>accum;
	var <>priorityQ;
	var <>now;
	var <>event;
	var <>exoStream;
	
	*new { |nChildren, wait, mark, accum, exoPattern|
		^super.new.nChildren_(nChildren.asStream
			).wait_(wait.asStream
			).mark_(mark.asStream
			).accum_(accum
			).exoStream_(exoPattern.asStream
		).init;
	}

	init {
		var nextEvent;
		priorityQ = PriorityQueue.new;
		now = 0;
	}
	nextExo { |event|
		var nextEv,
			nextNChildren,
			nextWait,
			nextMark;
		event = event.copy;
		nextEv = exoStream.next(event);
		nextEv.isNil.if({^nil});
		
		// logic gets convoluted here
		// pull the incoming streams as
		// needed and allow any of them to terminate the stream.
		nextNChildren = nChildren.next(event);
		nextWait = nextEv.wait ?? nextEv.delta ?? 1;
		nextMark = nextEv.mark ?? {mark.next(event)};
		((nextWait.notNil
			).and(nextMark.notNil
			).and(nextNChildren.notNil)
		).if({
			^nextEv.copy.putAll((
				nChildren: nextNChildren,
				wait: nextWait,
				mark: nextMark,
				generation: 0,
			))
		}, {
			^nil
		});
	}
	nextEndo { |event|
		var nextEv,
			nextNChildren,
			nextWait,
			maybeMark;
		// logic gets convoluted here, 
		// since we only pull the incoming streams as
		// needed and we to allow any of them to terminate the stream.
		nextNChildren = nChildren.next(event); 
		maybeMark = mark.next(event);
		nextWait = wait.next(event);
		
		((
			nextWait.notNil
			).and(maybeMark.notNil
			).and(nextNChildren.notNil)
		).if({
			accum.if({
				maybeMark = event.mark + maybeMark
			}, {
				maybeMark = maybeMark
			});
			^event.copy.putAll((
				nChildren: nextNChildren,
				wait: nextWait,
				mark: maybeMark,
				generation: event.generation + 1,
			))
		}, {
			^nil
		});
	}

	asStream {
		^Routine({ | ev | this.embedInStream(ev) })
	}
	
	embedInStream { | inevent, cleanup|
		var outevent, event, nexttime, nextExo, nextEvent;
		event = inevent;
		
		priorityQ.put(now, \exosurrogate);
		
		cleanup ?? { cleanup = EventStreamCleanup.new };
		
		while({
			priorityQ.notEmpty
		},{
			var step;
			nextEvent = priorityQ.pop;
			//may be a taken indicating we should check for an exo event
			//(These queue each other sequentially, so there is only ever one)
			(nextEvent === \exosurrogate).if({
				nextEvent = this.nextExo(event);
				//exo stream may have terminated...
				nextEvent.notNil.if({
					priorityQ.put(now + (nextEvent.delta), \exosurrogate);
				});
			});
			nextEvent.isNil.if({
				//out event was nil, so we are done. go home.
				priorityQ.clear;
				^cleanup.exit(inevent);
			}, {
				//outevent existed, so we emit it and queue its children
				// requeue substream
				nextEvent.nChildren.do({
					var nextEndo;
					nextEndo = this.nextEndo(nextEvent);
					nextEndo.notNil.if({
						priorityQ.put(now + (nextEndo.wait), nextEndo);
					});
				});
				nexttime = priorityQ.topPriority ? now;
				step = nexttime - now;
				nextEvent.put(\delta, step);
				now = nexttime;
				cleanup.update(nextEvent);
				event = nextEvent.yield;
			});
		});
		^event;
	}
}