//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Should probably be a pattern factory.
// Additional features installed for my needs:
// injecting tempo info into events
// providing per-event and per-bar callbacks to mess with shit.
// Future plans could include a state machine that skips around the sequence based on events
// Can I do this more easily with Pdefs?

// A lotof this could be simplified by using the clock; we are already stateful
// Quant.timingOffset is the key method here
PSWavvieBarSeq {
	var <beatsPerBar;
	var <>nBars;
	var <maxLen;
	var <>baseEvents;
	var <>parentEvent;
	var <>state;
	var <>barcallback;
	var <>notecallback;
	var <>debug;
	var <timePoints;
	var <idxptr=0;
	var <bartime=0.0;
	var <time=0.0;
	var <pat;
	var <stream;
	//private vars
	var <nextbartime;
	var <nextidxptr;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
	var <>clock;
	var <>sharedRandData;
	
	*new{|beatsPerBar=4,
		nBars=4,
		maxLen=1024,
		baseEvents,
		parentEvent,
		state,
		barcallback,
		notecallback,
		debug=false,
		timePoints|
		^super.newCopyArgs(
			beatsPerBar,
			nBars,
			maxLen,
			baseEvents ?? [(degree: 0)],
			parentEvent ?? (),
			state ?? (),
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
		nextbartime = timePoints[nextidxptr] ?? inf;
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
		// "proper" way:
		// evt = baseEvents.wrapAt(idxptr).copy.parent_(parentEvent);
		// easier-to-debug way:
		evt = parentEvent.copy.putAll(baseEvents.wrapAt(idxptr));
		evt['tempo'] = (clock ? TempoClock.default).tempo;
		evt['bartime'] = bartime;
		evt['time'] = time;
		evt['idxptr'] = idxptr;
		notecallback.notNil.if({
			var rout = Routine({|evt, seq| notecallback.value(evt, seq).yield});
			rout.randData = thisThread.randData;
			evt = rout.value(evt, this);
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
		stream.notNil.if({stream.stop});
		this.clock_(clock);
		this.sharedRandData = thisThread.randData;
		stream = thispat.play(clock, protoEvent, quant);
		stream.routine.randData = this.sharedRandData;
		^stream;
	}
	stop {
		//should i implement other stream methods?
		stream.notNil.if({stream.stop});
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
PSWavvieEvtSeq {
	var <beatsPerBar;
	var <>nBars;
	var <>parentEvent;
	var <>state;
	var <>barcallback;
	var <>notecallback;
	var <>debug;
	var <bartime=0.0;
	var <time=0.0;
	var <pat;
	var <stream;
	//private vars
	var <nextbartime;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
	var <>clock;
	var <>sharedRandData;
	
	*new{|beatsPerBar=4,
		nBars=4,
		parentEvent,
		state,
		barcallback,
		notecallback,
		debug=false|
		^super.newCopyArgs(
			beatsPerBar,
			nBars,
			parentEvent ?? (degree: 0),
			state ?? (),
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
				var rout = Routine({|seq| barcallback.value(seq).yield});
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
		evt = parentEvent.copy;
		evt['tempo'] = (clock ? TempoClock.default).tempo;
		evt['bartime'] = bartime;
		evt['time'] = time;
		notecallback.notNil.if({
			var rout = Routine({|evt, seq| notecallback.value(evt, seq).yield});
			rout.randData = thisThread.randData;
			evt = rout.value(evt, this);
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
	play {|clock, protoEvent, quant, trace=false|
		//This instance looks like a pattern, but in fact carries bundled state. Um.
		var thispat = pat;
		trace.if({thispat=pat.trace});
		stream.notNil.if({stream.stop});
		this.clock_(clock);
		this.sharedRandData = thisThread.randData;
		stream = thispat.play(clock, protoEvent, quant);
		stream.routine.randData = this.sharedRandData;
		^stream;
	}
	stop {
		//should i implement other stream methods?
		stream.notNil.if({stream.stop});
	}
}
//This guy manages a list of streams which can be dynamically added to

//TODO: add at quantised time
//TODO: skip processing rests
//TODO: insert metadata
PSWavvieStreamer {
	var <parentEvent;
	var <>state;
	var <>masterQuant;
	var <>notecallback;
	var <>debug;
	var <bartime=0.0;
	var <time=0.0;
	//private vars
	var <masterStream;
	var <childStreams;
	var <eventStreamPlayer;
	var <nextbartime;
	var <masterPat;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
	var <>clock;
	var <>sharedRandData;
	var <streamSpawner;
	
	*new{|parentEvent,
		state,
		quant,
		notecallback,
		debug=false|
		^super.newCopyArgs(
			parentEvent ?? (degree: 0),
			state ?? (),
			quant ?? 1.asQuant,
			notecallback, //null fn
			debug,
		).init;
	}
	init{
		childStreams = List.new;
		masterPat = Pspawner({|spawner|
			//init
			streamSpawner = spawner;
			bartime = 0.0;
			time = 0.0;
			this.sharedRandData = thisThread.randData;
			//iterate!
			inf.do({
				time.postln;
				streamSpawner.seq(Rest(masterQuant.quant));
			});
		});
	}
	add {|pat|
		var newStream = streamSpawner.par(pat, 0.0);
		childStreams.add(newStream);
		^newStream;
	}
	remove {|stream|
		streamSpawner.suspend(stream);
		childStreams.remove(stream);
	}
	decorateEvt{|evt|
		//[\beatlen, beatlen, \bartime, bartime, \nextbartime, nextbartime].postln;
		time = time + evt.delta;
		evt['tempo'] = (clock ? TempoClock.default).tempo;
		evt['bartime'] = bartime;
		evt['time'] = time;
		//Probably shouldn't bother calling for rests
		notecallback.notNil.if({
			var rout = Routine({notecallback.value(evt, this).yield});
			rout.randData = thisThread.randData;
			evt = rout.value;
			this.sharedRandData = rout.randData;
		});
		^evt;
	}
	play {|clock, protoEvent, quant, trace=false|
		var thispat = masterPat;
		protoEvent.notNil.if({parentEvent=protoEvent});
		quant.notNil.if({masterQuant=quant});
		masterStream.notNil.if({masterStream.stop});
		thispat = masterPat.collect({|evt| this.decorateEvt(evt)});
		trace.if({thispat=thispat.trace});
		this.clock_(clock ? TempoClock.default);
		this.sharedRandData = thisThread.randData;
		masterStream = thispat.play(this.clock, parentEvent, quant);
		masterStream.routine.randData = this.sharedRandData;
		^masterStream;
	}
	stop {
		//should i implement other stream methods?
		masterStream.notNil.if({masterStream.stop});
	}
	parentEvent_{|newParentEvent|
		parentEvent=newParentEvent;
		masterStream.notNil.if({masterStream.event=parentEvent});
	}
}
