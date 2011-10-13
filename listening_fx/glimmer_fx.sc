/* Granular effects for an analysed sound files, giving you just the frequencies that you want.

*/
//TODO: create synthdefs for various numbers of voices than 23
//TODO: respect numBuf
//TODO: create a version that does not depend on GlimmerTracker - i.e which takes a buffer pre-filled from function args
//TODO: handle any number of input AND output channels (by being ambisonic internally?)
//TODO: rewire in a dynamic-voicing style with Hash to get dynamic voicing, instead of the current manual one

GlimmerFilter {
	var outbus, inbus, <glimmerTracker, server, freqBuf, ratioBuf, freqBufPointer, group;
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*loadSynthDefs {
		//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate
		//input is assumed to be stereo
		//This one tracks frequencies in the input
		SynthDef.new(\glimmergrains,
			{|in, out,
				trigRate=10,
				inDuty=0.5, playDuty=0.5,
				ringTime=2.0, wideness=1,
				attack=0.01, decay=0.5,
				freqBuf, freqBufLength=10, freqBufPointer,
				numBuf, numBufLength=10,
				nVoices=23,
				feedbackGain = 0.5, feedbackLen=0.1|
				var trigRamp, voices, maxIndicesSoFar, mixedIn, outChannels, feedback;
				in = In.ar(in, 2);
				feedback = DelayL.ar(
					in: LocalIn.ar(2),
					maxdelaytime: 1.0,
					delaytime: feedbackLen-ControlRate.ir.reciprocal,
					mul:feedbackGain) ;
				mixedIn = Mix.ar(in+feedback);
				//poor-man's shared ring buffer
				freqBufPointer = In.kr(freqBufPointer);
				maxIndicesSoFar = RunningMax.kr(freqBufPointer);
				trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
				voices = Array.fill(maxVoices, {|i|
					var myRamp;
					var inGate, outGate;
					var inEnv, outEnv;
					var myFilterFreqLag, myDelayFreqLag;
					var myDelayFreq, myFilterFreq, myPan;
					var phaseI, panI;
					var sig;
					var alive;
					//permute phases
					phaseI = (i*29) % maxVoices;
					panI = (i*17) % maxVoices;
					alive = i<nVoices;
					//voice-local phase-offset ramp
					myRamp = Wrap.kr(trigRamp + (phaseI * maxVoices.reciprocal));
					inGate = (myRamp < inDuty) * alive;
					outGate = (myRamp < playDuty) * alive;
					inEnv = Linen.kr(inGate, attackTime: attack, releaseTime: decay);
					outEnv = Linen.kr(outGate, attackTime: attack, releaseTime: decay);
					myDelayFreqLag = TIRand.kr(lo:0, hi: freqBufLength.min(maxIndicesSoFar), trig:inGate);
					myFilterFreqLag = TIRand.kr(lo:0, hi: freqBufLength.min(maxIndicesSoFar), trig:inGate);
					Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511);
					myDelayFreq = BufRd.kr(numChannels:1, bufnum:freqBuf,
						phase: Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511),
						interpolation:1).max(10);
					myFilterFreq = BufRd.kr(numChannels:1, bufnum:freqBuf,
						phase: Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511),
						interpolation:1).max(80);
					sig = Resonz.ar(
						in: mixedIn*inEnv,
						freq: myFilterFreq,
						bwr: wideness
					);
					sig = CombL.ar(
						in: sig,
						maxdelaytime: 0.1,
						delaytime: myDelayFreq.reciprocal,
						decaytime: ringTime,
						mul:outEnv);
					Pan2.ar(
						in: sig,
						pos: ((2 * (panI+0.5) * maxVoices.reciprocal) -1),
						level: 1.0
					);
				});
				outChannels = Limiter.ar(LeakDC.ar(Mix.ar(voices)),1,0.01);
				LocalOut.ar(outChannels);
				Out.ar(out, outChannels);
			}	
		).add;
	}
	*new {|outbus, inbus, glimmerTracker|
		^super.newCopyArgs(outbus,inbus,glimmerTracker).init;
	}
	init {
		server = outbus.server;
		glimmerTracker.isNil.if({
			glimmerTracker = GlimmerTracker.new(inbus);
		});
	}
	play {
		freqBuf = Buffer(s, 513, 1);
		ratioBuf = Buffer(s, 512, 1);
		// alloc and set the values
		//pitches all 440Hz by default
		s.listSendMsg( freqBuf.allocMsg( freqBuf.setnMsg(0, 440!513) ).postln );
		//ratios all 1 by default.
		s.listSendMsg( ratioBuf.allocMsg( ratioBuf.setnMsg(0, 1!513) ).postln );
		//Now..
		freqBufPointer = Bus.control(s, 1);
		~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~inbus, \freqBuf, freqBuf, \freqBufPointer, freqBufPointer]);
		~fx = Synth.tail(~fxGroup, \glimmergrains, [\in, ~inbus, \out, ~outbus, \freqBuf, freqBuf, \freqBufPointer, freqBufPointer, \numBuf, ratioBuf, \trigRate, 1, \wideness, 1]);
		freqBufPointer.get(_.postln);
		freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});*/
	}
}

