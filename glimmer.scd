//TODO: (probably won't) create synthdefs for various numbers of voices than 23
//TODO: respect numBuf
//TODO: go to demand-rate recording. Control rate is lame.
//TODO: create a version that does not depend on  \findfreqs - i.e which takes a pre-filled buffer
//TODO: handle any number of input AND output channels (by being ambisonic internally?)
//TODO: use JITLib to make this compile nicely
//TODO: turn this into an instrument wiht nice intuitive GUI controls etc.

(
var maxVoices = 23; //primes make it easy to permute, since everything is co-prime

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
		//poor-man's ring buffer
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
).send(s);


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
}).send(s);
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
~inVox={ SoundIn.ar([0, 1]) }.play(target:~voxGroup, outbus:~sourceIns);
//s.volume.gui;
s.volume.volume= -20;
~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
~fx = Synth.tail(~fxGroup, \glimmergrains, [\in, ~sourceIns, \out, ~globalOuts, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer, \numBuf, ~ratioBuf, \trigRate, 1, \wideness, 1]);
~freqBufPointer.get(_.postln);
~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});