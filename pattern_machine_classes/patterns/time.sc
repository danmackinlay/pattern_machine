/*
  Event pattern returns relative local time (in beats) from moment of embedding
  A fake tempoclock might also have advantages

t=Pbind(
	\dur,1,
	\foo,Plocaltime(wrap:4),
).trace.play;
*/

Plocaltime : Pattern {
	var <>wrap;
	var <>repeats;
	var <>reset;
	*new { arg wrap=inf, repeats=inf, reset=false;
		^super.newCopyArgs(wrap, repeats, reset)
	}
	storeArgs { ^[wrap, repeats, reset] }
	embedInStream { arg inval;
		var wrapstream = wrap.asStream;
		var resetstream = reset.asStream;
		var localwrap, localreset;
		var time = 0;
		
		repeats.value(inval).do {
			localreset = resetstream.next; localreset ?? {^inval};
			localwrap = wrapstream.next; localwrap ?? {^inval};
			localreset.if({time=0.0});
			inval = time.yield;
			time = (time + inval.delta) % localwrap;
		};
		^inval;
	}
}
