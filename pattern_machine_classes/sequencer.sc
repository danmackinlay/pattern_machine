//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
// Should probably be a pattern factory.

PSWavvyseq {
	var <baseBarBeat;
	var <beatsPerBar;
	var <nBars;
	var <maxLen;
	var <>baseEvent;
	var <>state;
	var <>debug;
	var <timePoints;
	var <idxptr;
	var <timeptr;
	var <pat;
	var <stream;
	
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
		baseEvent,
		state,
		debug=false,
		timePoints|
		^super.newCopyArgs(
			baseBarBeat,
			beatsPerBar,
			nBars,
			maxLen,
			baseEvent ?? (degree: 0),
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
				var nexttimeptr, nextidxptr, delta, beatlen, evt;
				evt = baseEvent.copy;
				beatlen = nBars*beatsPerBar;
				nextidxptr = idxptr + 1;
				nexttimeptr = timePoints[nextidxptr];
				(nexttimeptr > beatlen).if({
					//next beat falls outside the bar. Hmm.
					delta = beatlen - (timeptr % beatlen);
					timeptr = 0;
					idxptr = -1;
				}, {
					delta = (nexttimeptr-timeptr).max(0);
					timeptr = timeptr + delta;
					idxptr = nextidxptr;
				});
				evt[\delta] = delta;
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