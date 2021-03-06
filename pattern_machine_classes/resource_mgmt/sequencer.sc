//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Additional features installed for my needs:
// injecting tempo info into events
// providing per-event and per-bar callbacks to mess with shit.
// Can I do this more easily with Pdefs?
// A lotof this could be simplified by using the clock; we are already stateful
// Quant.timingOffset is the key method here
PSBarSeq {
	var <beatsPerBar;
	var <>nBars;
	var <maxLen;
	var <>baseEvents;
	var <>parentEvent;
	var <>protoEvent;
	var <>state;
	var <>barcallback;
	var <>notecallback;
	var <>debug;
	var <timePoints;
	var <idxptr=0;
	var <bartime=0.0;
	var <time=0.0;
	var <pat;
	//private vars
	var <eventStreamPlayer;
	var <nextbartime;
	var <nextidxptr;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <evt; //debugger
	var <>clock;
	var <>sharedRandData;
	
	*new{|beatsPerBar=4,
		nBars=4,
		maxLen=1024,
		baseEvents,
		parentEvent,
		protoEvent,
		state,
		barcallback,
		notecallback,
		debug=false,
		timePoints|
		^super.newCopyArgs(
			beatsPerBar,
			nBars,
			maxLen,
			baseEvents ?? {[()]},
			parentEvent ?? {()},
			protoEvent ? Event.default,
			state ?? {()},
			barcallback,
			notecallback,
			debug,
		).init(timePoints ? []);
	}
	init{|newTimePoints|
		timePoints = Array.fill(maxLen, inf);
		newTimePoints.notNil.if({this.timePoints_(newTimePoints)});
		pat = Pspawner({|spawner|
			//init
			idxptr = -1;
			bartime = 0.0;
			time = 0.0;
			this.sharedRandData = thisThread.randData;
			//iterate!
			inf.do({
				this.prAdvanceTime(spawner);
			});
		});
	}
	prAdvanceTime{|spawner|
		//[\beatlen, beatlen, \bartime, bartime, \nextbartime, nextbartime].postln;
		beatlen = nBars*beatsPerBar;
		//set up the next iteration
		nextidxptr = idxptr + 1;
		nextbartime = timePoints[nextidxptr] ? inf;
		(nextbartime > beatlen).if({
			//next beat falls outside the bar. Wrap.
			barcallback.notNil.if({
				var rout = Routine({|seq| barcallback.value(seq).yield});
				rout.randData = thisThread.randData;
				rout.value(this);
				this.sharedRandData = rout.randData;
			});
			nextfirst = timePoints[0].min(beatlen);
			delta = (beatlen + nextfirst - bartime) % beatlen;
			bartime = nextfirst;
			idxptr = 0;
		}, {
			//this always plays all notes, at once if necessary; but we could skip ones if the seq changes instead?
			delta = (nextbartime-bartime).max(0);
			bartime = bartime + delta;
			idxptr = nextidxptr;
		});
		time = time + delta;
		
		//Advance logical time
		(delta>0).if({
			spawner.seq(Rest(delta));
		});
		
		// Create and schedule event:
		// easier-to-debug way:
		evt = Event.new(8, nil, protoEvent, true
			).putAll(parentEvent, baseEvents.wrapAt(idxptr));
		evt['tempo'] = (clock ? TempoClock.default).tempo;
		evt['bartime'] = bartime;
		evt['time'] = time;
		evt['idxptr'] = idxptr;
		notecallback.notNil.if({
			var rout = Routine({notecallback.value(evt, state, this).yield});
			rout.randData = thisThread.randData;
			evt = rout.value;
			this.sharedRandData = rout.randData;
		});
		//We may get back an event 
		//- in which case we wish to play it just once
		// otherwise we schedule it unquestioningly.
		spawner.par(
			evt.isKindOf(Event).if(
				{P1event(evt)},
				{evt})
		);
	}
	timePoints_{|newTimePoints|
		//needs infinte sentinel value after
		newTimePoints.sort.do({|v,i| timePoints[i]=v});
		timePoints[newTimePoints.size] = inf;
	}
	play {|clock, protoEvent, quant, trace=false|
		//This instance looks like a pattern, but in fact carries bundled state. Um.
		var thispat = pat;
		trace.if({thispat=pat.trace});
		eventStreamPlayer.notNil.if({eventStreamPlayer.stop});
		this.clock_(clock);
		this.sharedRandData = thisThread.randData;
		eventStreamPlayer = thispat.play(clock, protoEvent, quant);
		eventStreamPlayer.routine.randData = this.sharedRandData;
		^eventStreamPlayer;
	}
	stop {
		//should i implement other stream methods?
		eventStreamPlayer.notNil.if({eventStreamPlayer.stop});
	}
	seqFrom {|pattern, protoEvent|
		//return dur beats of a pattern
		var timePoints, baseEvents, stream, time;
		time = 0.0;
		baseEvents = List.new;
		timePoints = List.new;
		stream = pattern.asStream;
		stream.routine.randData = this.sharedRandData;
		//Do i need to copy this out again afterwards?
		({time<=beatlen}).while({
			var nextEv = stream.next(protoEvent ? Event.default);
			nextEv.isRest.not.if({
				timePoints.add(time);
				baseEvents.add(nextEv);
			});
			time = time + nextEv.delta;
		});
		^[timePoints, baseEvents];
	}
}
//subclass schmubclass; I can simplify this later if it works
PSEvtSeq {
	var <beatsPerBar;
	var <>nBars;
	var <>protoEvent;
	var <>parentEvent;
	var <>state;
	var <>barcallback;
	var <>notecallback;
	var <>debug;
	var <bartime=0.0;
	var <time=0.0;
	var <pat;
	var <eventStreamPlayer;
	//private vars
	var <nextbartime;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <evt; //debugger
	var <>clock;
	var <>sharedRandData;
	
	*new{|beatsPerBar=4,
		nBars=4,
		protoEvent,
		parentEvent,
		state,
		barcallback,
		notecallback,
		debug=false|
		^super.newCopyArgs(
			beatsPerBar,
			nBars,
			protoEvent ?? {Event.default},
			parentEvent ?? {()},
			state ? {()},
			barcallback,
			notecallback,
			debug,
		).init;
	}
	init{
		pat = Pspawner({|spawner|
			//init
			bartime = 0.0;
			time = 0.0;
			this.sharedRandData = thisThread.randData;
			//iterate!
			inf.do({
				this.prAdvanceTime(spawner);
			});
		});
	}
	prAdvanceTime{|spawner|
		//[\beatlen, beatlen, \bartime, bartime, \nextbartime, nextbartime].postln;
		beatlen = nBars*beatsPerBar;
		//set up the next iteration
		nextbartime = bartime + delta;
		(nextbartime > beatlen).if({
			//next beat falls outside the bar. Wrap.
			barcallback.notNil.if({
				var rout = Routine({|seq| barcallback.value(seq, state).yield});
				rout.randData = thisThread.randData;
				rout.value(this);
				this.sharedRandData = rout.randData;
			});
			nextfirst = (bartime + delta ) % beatlen;
			bartime = nextfirst;
		}, {
			bartime = bartime + delta;
		});
		time = time + delta;
		
		//Advance logical time
		(delta>0).if({
			spawner.seq(Rest(delta));
		});
		
		// Create and schedule event:
		evt = Event.new(8, nil, protoEvent, true).putAll(parentEvent, (
			tempo: (clock ? TempoClock.default).tempo,
			bartime: bartime,
			time: time,
		));
		notecallback.notNil.if({
			var rout = Routine({ notecallback.value(evt, state, this).yield});
			rout.randData = thisThread.randData;
			evt = rout.value;
			this.sharedRandData = rout.randData;
		});
		//We may get back an event 
		//- in which case we wish to play it just once
		// otherwise we schedule it unquestioningly.
		spawner.par(
			evt.isKindOf(Event).if(
				{P1event(evt)},
				{evt}
			)
		);
	}
	play {|clock, protoEvent, quant, trace=false|
		//This instance looks like a pattern, but in fact carries bundled state. Um.
		var thispat = pat;
		trace.if({thispat=pat.trace});
		eventStreamPlayer.notNil.if({eventStreamPlayer.stop});
		this.clock_(clock);
		this.sharedRandData = thisThread.randData;
		eventStreamPlayer = thispat.play(clock, protoEvent, quant);
		eventStreamPlayer.routine.randData = this.sharedRandData;
		^eventStreamPlayer;
	}
	stop {
		//should i implement other stream methods?
		eventStreamPlayer.notNil.if({eventStreamPlayer.stop});
	}
}
//This guy manages a list of streams which can be dynamically added to

//TODO: skip processing rests
//TODO: check cleanup of stopped streams
//TODO: check this starts on the correct beat.
PSStreamer {
	var <>state;
	var <>masterQuant;
	var <>notecallback;
	var <>tickcallback;
	var <>debug;
	var <parentEvent;
	var <protoEvent;
	var <time=0.0;
	//private vars
	var <childStreams;
	var <eventStreamPlayer;
	var <masterStream;
	var <masterPat;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>clock;
	var <evt; //debugger
	var <>sharedRandData;
	var <streamSpawner;
	var <>streamcounter = 0;
	
	*new{|state,
		quant,
		notecallback,
		tickcallback,
		debug=false,
		parentEvent|
		^super.newCopyArgs(
			state ?? {()},
			quant ?? {[1,0,0].asQuant},
			notecallback, //null fn
			tickcallback,
			debug,
		).init.parentEvent_(parentEvent ? Event.default);
	}
	init{
		childStreams = IdentityDictionary.new;
		masterPat = Pspawner({|spawner|
			this.spawnRout(spawner);
		});
	}
	spawnRout {|spawner|
		//init
		streamSpawner = spawner;
		this.sharedRandData = thisThread.randData;
		//Try to line up with clock (does this work?)
		streamSpawner.wait(clock.timeToNextBeat(masterQuant.quant));
		time = 0.0;
		//iterate!
		inf.do({
			debug.if({
				[\time, time, clock.beats].postln;
			});
			//Advance time
			streamSpawner.wait(masterQuant.quant);
			tickcallback.notNil.if({
				var rout = Routine({tickcallback.value(time, state, this).yield});
				rout.randData = thisThread.randData;
				evt = rout.value;
				this.sharedRandData = rout.randData;
			});
		});
	}
	add {
		arg newpat, delta=0, id;
		var nextstream;
		id = id ?? {streamcounter = streamcounter + 1};
		//let streams know their names
		nextstream = streamSpawner.par(
			Pbindf(
				newpat.asPattern,
				\scount, Pseries.new,
				\sid, id,
				\ltime, Plocaltime.new
			), delta
		);
		childStreams[id].notNil.if( {
			streamSpawner.suspend(childStreams[id]);
			childStreams.removeAt(id);
		});
		childStreams[id] = nextstream;
		^id;
	}
	removeAt {|id|
		childStreams[id].notNil.if({
			streamSpawner.suspend(childStreams[id]);
			childStreams.removeAt(id);
		});
	}
	at {|id|
		^childStreams[id];
	}
	decorateEvt{|event|
		evt = parentEvent.copy.putAll(event, (
			tempo: (clock ? TempoClock.default).tempo,
			time: time,
		));
		//We allow any non-rests to get decorated
		//You shouldn't change delta, so
		//rests really should not be touched anyway.
		((notecallback.notNil).and(event.isRest.not)).if({
			var rout = Routine({notecallback.value(evt, state, this).yield});
			rout.randData = thisThread.randData;
			evt = rout.value;
			this.sharedRandData = rout.randData;
		});
		time = time + evt.delta;
		^evt;
	}
	asStream {|trace=false|
		var thispat = masterPat;
		masterStream.notNil.if({masterStream.stop});
		thispat = masterPat.collect({|evt| this.decorateEvt(evt)});
		trace.if({thispat=thispat.trace});
		masterStream = thispat.asStream;
		^masterStream;
	}
	play {|clock, evt, quant, trace=false|
		quant.notNil.if({masterQuant=quant});
		evt.notNil.if({
			this.protoEvent_(evt);
		});
		this.clock_(clock ? TempoClock.default);
		this.sharedRandData = thisThread.randData;
		eventStreamPlayer = this.asStream(trace:trace
			).asEventStreamPlayer(protoEvent ? Event.default).play(clock);
		eventStreamPlayer.routine.randData = this.sharedRandData;
		^eventStreamPlayer;
	}
	stop {
		//should i implement other stream methods?
		eventStreamPlayer.notNil.if({eventStreamPlayer.stop});
	}
	stopChildren {
		childStreams.do({
			arg stream, id;
			streamSpawner.suspend(stream);
		});
		childStreams.keys.do({
			arg id;
			childStreams.removeAt(id);
		});
	}
	protoEvent_{
		arg newProtoEvent;
		parentEvent = Event.new(8, nil, newProtoEvent, true
			).putAll(parentEvent);
		protoEvent = newProtoEvent;
		eventStreamPlayer.notNil.if({
			eventStreamPlayer.event = protoEvent;
		});
	}
	parentEvent_{
		arg newParentEvent;
		parentEvent = newParentEvent;
	}
}
//convenience override to the global state passed in.
PSNoteCallback {
	var <localstate;
	var <>callbackfn;
	*new {
		arg state, callbackfn;
		^super.newCopyArgs(state, callbackfn);
	}
	value {
		arg evt, state, seq;
		^evt.make(callbackfn.value(evt, localstate, seq));
	}
}
