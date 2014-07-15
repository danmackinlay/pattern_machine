/*Time wrangling Event patterns
(should they be mere value patterns?)
*/

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
			event.notNil;
		}{
			var intendedNextDelta, actualNextDelta, indisorder, modEvent;
			indisorder = disorderstream.next;
			indisorder ?? {^event;};
			intendedNextDelta = event.atFail(\delta, 1) + slip;
			actualNextDelta = (1.0-(indisorder.asFloat.rand)) * intendedNextDelta;
			slip = intendedNextDelta - actualNextDelta;
			modEvent = event.copy.put(\delta, actualNextDelta);
			modEvent.yield;
		}
		^event;
	}
}

//quantize timings wrt a given fraction of a beat (could do full-blown Quant but looks boring)
/* will need
nextTimeOnGrid { arg quant = 1, phase = 0;
	if (quant == 0) { ^this.beats + phase };
	if (quant < 0) { quant = beatsPerBar * quant.neg };
	if (phase < 0) { phase = phase % quant };
	^roundUp(this.beats - baseBarBeat - (phase % quant), quant) + baseBarBeat + phase
	}
*/
//nb, this uses a purely local notion of time because raiding the Tempoclock is lame; but could make finding the bar boundaries impossible.
//TODO: provide a "time reset" input to allow start-of-bar markings or something
//TODO: actual exponential random
//TODO: provide interpolation of quantization.
Pquantize : FilterPattern {
	var <>quant,<>strength,<>barlen,<>tol, <>debug;
	*new { arg pattern, quant=1/4, strength=1.0, barlen=4, tol=0.0001, debug=false;
		^super.new(pattern).quant_(quant).strength_(strength).barlen_(barlen).tol_(tol).debug_(debug);
	}
	
	storeArgs { ^[pattern, quant, strength, barlen, tol, debug] }

	embedInStream { arg event;
		var patternstream = pattern.asStream;
		var quantstream = quant.asStream;
		var strengthstream = strength.asStream;
		var intendedTime = 0.0, actualTime=0.0;
		var localbarlen = barlen.value(event);
		while {
			event = patternstream.next(event);
			event.notNil;
		}{
			var intendedNextTime, quantizedNextTime, actualNextTime;
			var nextDelta, inquant, instrength, modEvent;
			inquant = quantstream.next(event);
			inquant ?? {^event;}; //return on end of sub pattern
			instrength = strengthstream.next(event);
			instrength ?? {^event;}; //return on end of sub pattern
			intendedNextTime = event.delta + intendedTime;
			quantizedNextTime = intendedNextTime.round(inquant).max(actualTime);
			actualNextTime = ((1-instrength) * intendedNextTime) + (instrength*quantizedNextTime);
			nextDelta = actualNextTime - actualTime;
			debug.if{[actualTime, intendedNextTime, quantizedNextTime, inquant, instrength, actualNextTime, nextDelta].postln};
			actualTime = actualNextTime;
			intendedTime = intendedNextTime;
			// ignore tolerance for the minute
			//((time.round(localbarlen)-time).abs<tol).if ({time=0});
			// The below logic won't quite work; we need to decrement both counters by the same amount
			//actualTime = actualTime % localbarlen;
			//intendedTime = intendedTime % localbarlen;
			modEvent = event.copy.put(\delta, nextDelta);
			modEvent.yield;
		}
		^event;
	}
}

