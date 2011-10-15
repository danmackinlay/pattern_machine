/* Granular effects for an analysed sound files, giving you just the frequencies that you want.

*/
//TODO: create synthdefs for various numbers of voices than 23
//TODO: respect numBuf
//TODO: handle any number of input AND output channels (by being ambisonic internally?)
//TODO: rewire in a dynamic-voicing style with Hash to get dynamic voicing, instead of the current manual one
//TODO: go to demand-rate recording. Control rate is lame.
//TODO: switch to Tartini
//TODO: don't create and explicit Control bus for the freqBufPointer. kr bus can be implicity created.
//TODO: disambiguate variables that will be used to update isntance vars by making them lowercase, and instance vars camelCase
//TODO: bound freqlag above.

GlimmerFilter {
	var <outbus, <inbus, <server, <freqBuf, <ratioBuf, <freqBufPointer, <fxgroup, <fxsynth;
	var <freqs;
	
	classvar maxVoices = 23;
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*loadSynthDefs {
		//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate
		//input is assumed to be stereo
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
	*new {
		^super.new.init;
	}
	init {
		freqs = [440];
	}
	freqs_ {|freqlist|
		freqs = freqlist;
		freqBuf.isNil.not.if({
			freqBuf.setn(freqs);
			freqBufPointer.set(freqs.size-1);
		});
	}
	play { |out, in, fxGroup|
		fork { this.playRoutine(out, in, fxGroup); };
	}	
	
	playRoutine {|out, in, fxGroup|
		server = out.server;
		outbus = out;
		inbus = in ? out;
		[\fxGroup, fxGroup].postln;
		fxGroup.isNil.if({fxGroup = Group.new(server);});
		fxgroup = fxGroup;
		[\fxgroup, fxgroup].postln;
		freqBuf = Buffer(server, 513, 1);
		ratioBuf = Buffer(server, 512, 1);
		// alloc and set the values
		//pitches all 440Hz by default
		server.listSendMsg( freqBuf.allocMsg( freqBuf.setnMsg(0, freqs) ).postln );
		//ratios all 1 by default.
		server.listSendMsg( ratioBuf.allocMsg( ratioBuf.setnMsg(0, 1!513) ).postln );
		//Now..
		server.sync;
		freqBufPointer = Bus.control(server, 1);
		server.sync;
		freqBufPointer.set(0);
		fxsynth = Synth.new(
			\glimmergrains,
			[\in, inbus, \out, outbus, \freqBuf, freqBuf, \freqBufPointer, freqBufPointer, \numBuf, ratioBuf, \trigRate, 1, \wideness, 1],
			target: fxgroup);
	}
}

ListeningGlimmerFilter : GlimmerFilter {
	var <listenbus, <listensynth, <listengroup;
		
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*loadSynthDefs {
		//This guy tracks frequencies in the input
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
  freqs {|freqlist|
	  //do nothing, to prevent parent class's interfering sefault behaviour.
	}
	play { |out, in, listenin, fxGroup, listenGroup|
		fork { this.playRoutine(out, in, listenin, fxGroup, listenGroup); };
	}	
	
	playRoutine { |out, in, listenin, fxGroup, listenGroup|
		super.playRoutine(out, in, fxGroup);
		server.sync;
		[\listenGroup, listenGroup].postln;
		listenGroup.isNil.if({
			listenGroup = Group.new(fxgroup, addAction: \addBefore);
		});
		listengroup = listenGroup;
		[\listenGroup, listenGroup].postln;
		listenbus = listenin ? in;
		listensynth = Synth.new(
			\findfreqs,
			[\in, listenbus, \freqBuf, freqBuf, \freqBufPointer, freqBufPointer],
			target: listengroup);
	}
}
