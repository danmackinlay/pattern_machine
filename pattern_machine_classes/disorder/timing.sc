//shuffle events about in time
//this implementtion rearranges them by up to the time of the next note;
// An alternative method would shuffle all events out by an arbitrary amount;
// That would need more bookkeeping
// This one is easier but probably fucks chords
Pstumble : FilterPattern {
	var <>disorder;
	*new { arg pattern, disorder;
		^super.new(pattern).disorder_(disorder);
	}
	
	storeArgs { ^[pattern, disorder] }

	embedInStream { arg event;
		var patternstream = pattern.asStream;
		var disorderstream = disorder.asStream;
		var slip = 0.0;
		
		while {
			event = patternstream.next(event);
			\inev.postln;
			event.postcs;
			\patt.postln;
			patternstream.postcs;
			event.notNil;
		}{
			var intendedNextTime, actualNextTime, indisorder, modEvent;
			indisorder = disorderstream.next;
			\indisorder.postln;
			indisorder.postcs;
			
			intendedNextTime = event[\delta] + slip;
			actualNextTime = (1.0-(indisorder.asFloat.rand)) * intendedNextTime;
			slip = intendedNextTime - actualNextTime;
			modEvent = event.copy.put(\delta, actualNextTime);
			\slip.postln;
			slip.postcs;
			\modEvent.postln;
			modEvent.postcs;
			
			event = modEvent.yield;
		}
		^event;
	}
}
