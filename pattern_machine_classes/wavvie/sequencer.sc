//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Should probably be a pattern factory.
// Additional features installed for my needs:
// injecting tempo info into events
// providing per-event and per-rep callbacks to mess with shit.
// Future plans could include a state machine that skips around the sequence based on events
// More general sequence that could be extracted from this would create stateful patterns that allowed per-event updates

PSWavvieSeq {
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
	//private var, made members for ease of debugging.
	var <nextbartime;
	var <nextidxptr;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
	var <>clock;
	var <>sharedRandData;
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
	}
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
		spawner.par(P1event(evt));
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