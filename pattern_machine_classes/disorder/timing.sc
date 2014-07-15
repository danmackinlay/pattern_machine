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
	var <>quant,<>barlen,<>tol;
	*new { arg pattern, quant=1/4, barlen=4, tol=0.0001;
		^super.new(pattern).quant_(quant).barlen_(barlen).tol_(tol);
	}
	
	storeArgs { ^[pattern, quant, barlen, tol] }

	embedInStream { arg event;
		var patternstream = pattern.asStream;
		var quantstream = quant.asStream;
		var intendedTime = 0.0, actualTime=0.0;
		var localbarlen = barlen.value(event);
		while {
			event = patternstream.next(event);
			event.notNil;
		}{
			var intendedNextTime, actualNextTime, nextDelta, inquant, modEvent;
			inquant = quantstream.next;
			inquant ?? {^event;}; //return on end of sub pattern
			intendedNextTime = event.atFail(\delta, 1)+intendedTime;
			actualNextTime = intendedNextTime.round(inquant).max(actualTime);
			nextDelta = actualNextTime - actualTime;
			//[time, intendedNextTime, actualNextTime, nextDelta].postln;
			actualTime = actualNextTime;
			intendedTime = intendedNextTime;
			// ignore tolerance for the minute
			//((time.round(localbarlen)-time).abs<tol).if ({time=0});
			actualTime = actualTime % localbarlen;
			intendedTime = intendedTime % localbarlen;
			modEvent = event.copy.put(\delta, nextDelta);
			modEvent.yield;
		}
		^event;
	}
}

