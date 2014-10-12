//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Should probably be a pattern factory.

PSWavvyseq {
	var <baseBarBeat;
	var <beatsPerBar;
	var <>nBars;
	var <maxLen;
	var <>baseEvents;
	var <>state;
	var <>debug;
	var <timePoints;
	var <idxptr;
	var <timeptr;
	var <pat;
	var <stream;
	//private var, made memebrs for ease of debugging.
	var <nexttimeptr;
	var <nextidxptr;
	var <>delta;
	var <beatlen;
	var <nextfirst=0;
	var <>evt;
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
		state,
		debug=false,
		timePoints|
		^super.newCopyArgs(
			baseBarBeat,
			beatsPerBar,
			nBars,
			maxLen,
			baseEvents ?? [(degree: 0)],
			state ?? (),
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
				nexttimeptr = timePoints[nextidxptr];
				evt = baseEvents.wrapAt(idxptr).copy;
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
	play {|clock|
		//This inst looks like a pattern, but in fact carries bundled state. Um.
		stream.notNil.if({stream.stop});
		stream = pat.play(clock);
		^stream;
	}
	stop {
		//should i implement other stream methods?
		stream.notNil.if({stream.stop});
	}
}