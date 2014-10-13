//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Should probably be a pattern factory.
// Additional features installed for my needs:
// tempo shifting
// injecting tempo info into events
// providing per-event and per-rep callbacks to mess with shit.
// Future plans could include a state amchine that skips around the sequence based on events

PSWavvyseq {
	var <baseBarBeat;
	var <beatsPerBar;
	var <>nBars;
	var <maxLen;
	var <>baseEvents;
	var <>parentEvent;
	var <>state;
	var <>timerate=1.0;
	var <>debug;
	var <timePoints;
	var <idxptr;
	var <timeptr;
	var <pat;
	var <stream;
	//private var, made members for ease of debugging.
	var <nexttimeptr;
	var <nextidxptr;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
	var <>clock;
	//stream wrangling
	var <>barcallback;
	var <>notecallback;
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
	}
	*new{|baseBarBeat=0,
		beatsPerBar=4,
		nBars=4,
		maxLen=1024,
		baseEvents,
		parentEvent,
		state,
		timerate=1.0,
		debug=false,
		timePoints|
		^super.newCopyArgs(
			baseBarBeat,
			beatsPerBar,
			nBars,
			maxLen,
			baseEvents ?? [(degree: 0)],
			parentEvent,
			state ?? (),
			timerate,
			debug,
		).init(timePoints);
	}
	init{|newTimePoints|
		idxptr = -1;
		timeptr = 0.0;
		timePoints = Array.fill(maxLen, inf);
		newTimePoints.notNil.if({this.timePoints_(newTimePoints)});
		pat = Pspawner({|spawner|
			inf.do({
				[beatlen, timeptr, nexttimeptr].postln;
				beatlen = nBars*beatsPerBar;
				nextidxptr = idxptr + 1;
				nexttimeptr = timePoints[nextidxptr] ?? inf/timerate;
				evt = baseEvents.wrapAt(idxptr).copy.parent_(parentEvent);
				evt['tempo'] = (clock ? TempoClock.default).tempo;
				evt['timerate'] = timerate;
				(nexttimeptr > beatlen).if({
					//next beat falls outside the bar. Hmm.
					barcallback.notNil.if({
						barcallback.value(this);
					});
					nextfirst = timePoints[0].min(beatlen);
					delta = (beatlen + nextfirst - timeptr) % beatlen;
					timeptr = nextfirst;
					idxptr = 0;
					//evt = Rest(delta);
				}, {
					//this always plays all notes; but we could skip ones if the seq changes instead?
					delta = (nexttimeptr-timeptr).max(0);
					timeptr = timeptr + delta;
					idxptr = nextidxptr;
					evt[\delta] = delta;
				});
				//at the moment this will desync if you change the note delta in the callback
				// can change that if useful
				notecallback.notNil.if({
					notecallback.value(this);
				});
				spawner.seq(evt);
			});
		});
	}
	timePoints_{|newTimePoints|
		newTimePoints.sort.do({|v,i| timePoints[i]=v})
	}
	play {|clock, protoEvent, quant|
		//This inst looks like a pattern, but in fact carries bundled state. Um.
		stream.notNil.if({stream.stop});
		this.clock_(clock);
		stream = pat.play(clock, protoEvent, quant);
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