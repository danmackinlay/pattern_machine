/* Track pitches in an input and write 'em to a buffer for use in 
pitch sensitive effects (such as GlimmerFilter)
*/

//TODO: go to demand-rate recording. Control rate is lame.
//TODO: switch to Tartini


GlimmerTracker {
	var sourceIns, freqBufPointer, <freqBuf, <ratioBuf, server, group;
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*loadSynthDefs {
		//This one tracks frequencies in the input
		SynthDef.new(\findfreqs, {|in, rate = 10, gate=1, freqBuf, freqBufPointer|
			var hasFreq, freq, index, writing=0;
			rate = rate.min(ControlRate.ir/2);//so triggers work
			//we presume freqBuf has 513 samples, and use 512. Why not?
			#freq, hasFreq = Pitch.kr(Mix.ar(In.ar(in, 2)), execFreq: rate);
			writing = hasFreq* gate;
			index = Stepper.kr(Impulse.kr(rate) * writing, max: 511);
			index = (index+(512*(1-writing))).min(512);  //this last bit moves the read head to the end when there is no freq. Maybe I should do this at demand rate instead?
			//freq.poll(10, \written);
			BufWr.kr(
				inputArray: freq,
				bufnum: freqBuf,
				phase: index
			);
			BufRd.kr(numChannels:1,
				bufnum: freqBuf,
				phase: index,
				interpolation:1
			);//.poll(10, \read);
			Out.kr(freqBufPointer, Gate.kr(index, hasFreq));
		}/*,
		metadata: (specs: (
			cutoff: \freq, volume: \amp)
		)*/).add;
	}
	*new{|defaultFreq=440|
		^super.new.init;
	}
	init {
	}
	play {|target, addAction|
		//we 
		
	}
}