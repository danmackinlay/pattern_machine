
// event pattern returns relative local time (in beats) from moment of embedding
// A fake tempoclock might also have advantages

Plocaltime : Pattern {
	var <>repeats;
	*new { arg repeats=inf;
		^super.newCopyArgs(repeats)
	}
	storeArgs { ^[repeats] }
	embedInStream { arg inval;
		var time = 0;
		repeats.value(inval).do {
			inval = time.yield;
			time = time + inval.delta;
		};
		^inval;
	}
}
