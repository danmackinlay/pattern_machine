
// event pattern returns relative local time (in beats) from moment of embedding
// A fake tempoclock might also have advantages

Plocaltime : Pattern {
	var <>wrap;
	var <>repeats;
	*new { arg wrap=inf,repeats=inf;
		^super.newCopyArgs(wrap, repeats)
	}
	storeArgs { ^[wrap, repeats] }
	embedInStream { arg inval;
		var time = 0;
		repeats.value(inval).do {
			inval = time.yield;
			time = (time + inval.delta) % wrap;
		};
		^inval;
	}
}
