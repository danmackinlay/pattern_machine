//A stateful stream (or pattern, or stream/pattern factory, i haven't decided) that plays a sequence
PSWavvyseq {
	 var <baseBarBeat;
	 var <beatsPerBar;
	 var <nBars;
	 var <maxLen;
	 var <timePoints;
	 var <idxptr=0;
	 var <timeptr;
	 
 	*initClass{
 		StartUp.add({
 			this.loadSynthDefs;
 		});
 	}
 	*loadSynthDefs {
	}
	*new{|baseBarBeat=0, beatsPerBar=4, nBars=4, maxLen=1024, timePoints|
		^super.newCopyArgs(
			baseBarBeat, beatsPerBar, nBars, maxLen
		).init(timePoints);
	}
	init{|newTimePoints|
		timePoints = Array.fill(maxLen, inf);
		newTimePoints.notNil.if({this.timePoints_(newTimePoints)});
	}
	timePoints_{|newTimePoints|
		newTimePoints.do({|v,i| timePoints[i]=v})
	}
}