//TODO: create synthdefs for various numbers of voices than 20
//TODO: respect nVoices
//TODO: respect numBuf
//TODO: resonant filter
//TODO: feedback
//TODO: go to demand-rate recording. Control rate is lame.

(
SynthDef.new(\findfreqs, {|in, rate = 10, gate=1, freqBuf, freqBufPointer|
	var hasFreq, freq, index, writing=0;
	rate = rate.min(ControlRate.ir/2);//so triggers work
	//we presume freqBuf has 513 samples, and use 512. Why not?
	#freq, hasFreq = Pitch.kr(In.ar(in), execFreq: rate);
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
}).send(s);


//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate
//input is assumed to be stereo

~maxVoices = 23; //primes make it easy to permute, since everything is co-prime

SynthDef.new(\glimmergrains,
	{|in, out,
		trigRate=10,
		inDuty=0.5, playDuty=0.5,
		reso=2.0,
		attack=0.01, decay=0.5,
		freqBuf, freqBufLength=10, freqBufPointer,
		numBuf, numBufLength=10,
		nVoices=10|
		var trigRamp, voices, maxIndicesSoFar, mixedIn;
		in = In.ar(in);
		mixedIn = Mix.ar(in);
		//poor-man's ring buffer
		freqBufPointer = In.kr(freqBufPointer);
		maxIndicesSoFar = RunningMax.kr(freqBufPointer);
		trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
		voices = Array.fill(~maxVoices, {|i|
			var myRamp;
			var inGate, outGate;
			var inEnv, outEnv;
			var myDelayFreqLag;
			var myFreq, myPan;
			var phaseI, panI;
			//permute phases
			phaseI = (i*29) % ~maxVoices;
			panI = (i*17) % ~maxVoices;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + (phaseI * ~maxVoices.reciprocal));
			inGate = myRamp < inDuty;
			outGate = myRamp < playDuty;
			inEnv = Linen.kr(inGate, attackTime: attack, releaseTime: decay);
			outEnv = Linen.kr(outGate, attackTime: attack, releaseTime: decay);
			myDelayFreqLag = TIRand.kr(lo:0, hi: freqBufLength.min(maxIndicesSoFar), trig:inGate);
			Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511);
			myFreq = BufRd.kr(numChannels:1, bufnum:freqBuf,
				phase: Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511),
				interpolation:1).max(10);

			Pan2.ar(
				in: CombL.ar(
					in: mixedIn*inEnv,
					maxdelaytime: 0.1,
					delaytime: myFreq.reciprocal,
					decaytime: reso,
					mul:outEnv),
				pos: ((2 * (panI+0.5) * ~maxVoices.reciprocal) -1),
				level: 1.0
			);
		});
		Out.ar(out, Limiter.ar(LeakDC.ar(Mix.ar(voices)),1,0.01));
	}	
).send(s);

SynthDef.new(\hardwarein,
	{|in, out|
		in = SoundIn.ar(in);
		// Amplitude.kr(in, releaseTime:1).poll(1, \inamp);
		Out.ar(out, in);}
).send(s);
)

(
~freqBuf = Buffer(s, 513, 1);
~ratioBuf = Buffer(s, 512, 1);
// alloc and set the values
//pitches all 440Hz by default
s.listSendMsg( ~freqBuf.allocMsg( ~freqBuf.setnMsg(0, 440!513) ).postln );
//ratios all 1 by default.
s.listSendMsg( ~ratioBuf.allocMsg( ~ratioBuf.setnMsg(0, 1!513) ).postln );
//Now..
~globalOuts = Bus.new(\audio, 0, 4);
~freqBufPointer = Bus.control(s, 1);
~sourceIns = Bus.audio(s, 2);
~voxGroup = Group.new(s);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);
//read hardware in at head of ~voxGroup
~inVox = Synth(\hardwarein, [\in, 0, \out, ~sourceIns], ~voxGroup);
//s.volume.gui;
s.volume.volume= -20;
~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
~fx = Synth.tail(~fxGroup, \glimmergrains, [\in, ~sourceIns, \out, ~globalOuts, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer, \numBuf, ~ratioBuf, \trigRate, 1]);
~freqBufPointer.get(_.postln);
~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});
)