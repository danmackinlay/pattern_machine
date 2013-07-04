/* create glimmering soundscapes without manual trweaking using machine listening.
*/
//TODO: go to demand-rate recording. Control rate is lame.
//TODO: create a version that does not depend on  \findfreqs - i.e which takes a pre-filled buffer
//TODO: handle any number of input AND output channels (by being ambisonic internally?)
//TODO: turn this into an instrument with nice intuitive GUI controls etc.
//TODO: simplify.

(
var maxVoices = 23; //primes make it easy to permute, since everything is co-prime

//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate
//input is assumed to be stereo

SynthDef.new(\glimmergrains,
	{|inbus, outbus,
		trigRate=10,
		duty=0.5,
		ringTime=2.0, wideness=1,
		attack=0.01, decay=0.5,
		freqBuf, freqMemory=10, freqBufPointer,
		ratioBuf,
		intensity=1.0,
		feedbackGain = 0.5, feedbackLen=0.1|
		var trigRamp, voices, maxIndicesSoFar, mixedIn, outChannels, feedback;
		inbus = In.ar(inbus, 2);
		feedback = DelayL.ar(
			in: LocalIn.ar(2),
			maxdelaytime: 1.0,
			delaytime: feedbackLen-ControlRate.ir.reciprocal,
			mul:feedbackGain) ;
		mixedIn = Mix.new(inbus+feedback);
		//poor-man's shared ring buffer
		freqBufPointer = In.kr(freqBufPointer);
		maxIndicesSoFar = RunningMax.kr(freqBufPointer);
		trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
		voices = Array.fill(maxVoices, {|i|
			var myRamp;
			var gate, env;
			var myFilterFreqLag, myDelayFreqLag;
			var myDelayFreq, myFilterFreq, myPan;
			var phase, pan, threshold;
			var ratioPointerFilt, ratioPointerDelay;
			var ratioFilt, ratioDelay;
			var sig;
			var alive;
			//permute phases
			phase = Rand.new;
			pan = Rand.new;
			threshold = Rand.new;
			alive = threshold<intensity;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + phase );
			gate = (myRamp < duty) * alive;
			env = Linen.kr(gate, attackTime: attack, releaseTime: decay);
			ratioPointerFilt = TIRand.kr(lo:0, hi: BufFrames.kr(ratioBuf), trig: gate);
			ratioPointerDelay = TIRand.kr(lo:0, hi: BufFrames.kr(ratioBuf), trig: gate);
			ratioFilt = BufRd.kr(1,ratioBuf, ratioPointerFilt);
			ratioDelay = BufRd.kr(1,ratioBuf, ratioPointerDelay);
			myDelayFreqLag = TIRand.kr(lo:0, hi: freqMemory.min(maxIndicesSoFar), trig:gate);
			myFilterFreqLag = TIRand.kr(lo:0, hi: freqMemory.min(maxIndicesSoFar), trig:gate);
			Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511);
			myDelayFreq = (BufRd.kr(numChannels:1, bufnum:freqBuf,
				phase: Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511),
				interpolation:1)* ratioFilt).max(10);
			myFilterFreq = (BufRd.kr(numChannels:1, bufnum:freqBuf,
				phase: Wrap.kr(freqBufPointer - myDelayFreqLag, lo: 0, hi: 511),
				interpolation:1)*ratioDelay).max(80);
			sig = Resonz.ar(
				in: mixedIn*env,
				freq: myFilterFreq,
				bwr: wideness
			);
			sig = CombL.ar(
				in: sig,
				maxdelaytime: 0.1,
				delaytime: myDelayFreq.reciprocal,
				decaytime: ringTime,
				mul:env);
			Pan2.ar(
				in: sig,
				pos: (2 * pan -1),
				level: 1.0
			);
		});
		outChannels = Limiter.ar(LeakDC.ar(Mix.new(voices)),1,0.01);
		LocalOut.ar(outChannels);
		Out.ar(outbus, outChannels);
	}
).add;


SynthDef.new(\findfreqs, {|inbus, rate = 10, gate=1, freqBuf, freqBufPointer|
	var hasFreq, freq, index, writing=0;
	rate = rate.min(ControlRate.ir/2);//so triggers work
	//we presume freqBuf has 513 samples, and use 512. Why not?
	#freq, hasFreq = Pitch.kr(Mix.new(In.ar(inbus, 2)), execFreq: rate);
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
}).add;
)

(
fork {
	~freqBuf = Buffer(s, 513, 1);
	~ratioBuf = Buffer(s, 512, 1);
	// alloc and set the values
	//pitches all 440Hz by default
	s.listSendMsg( ~freqBuf.allocMsg( ~freqBuf.setnMsg(0, 440!513) ).postln );
	//ratios all 1 by default.
	s.listSendMsg( ~ratioBuf.allocMsg( ~ratioBuf.setnMsg(0, 1!513) ).postln );
	//Now..
	s.sync;
	~globalOuts = Bus.new(\audio, 0, 4);
	~freqBufPointer = Bus.control(s, 1);
	~sourceIns = Bus.audio(s, 2);
	~voxGroup = Group.new(s);
	s.sync;
	~fxGroup = Group.after(~voxGroup);
	s.sync;
	~outGroup = Group.after(~fxGroup);
	//read hardware in at head of ~voxGroup
	~inVox={ SoundIn.ar([0, 1]) }.play(target:~voxGroup, outbus:~sourceIns);
	//s.volume.gui;
	s.volume.volume= -20;
	~listener = Synth.head(~fxGroup, \findfreqs, [\inbus, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
	~fx = Synth.tail(~fxGroup, \glimmergrains, [\inbus, ~sourceIns, \outbus, ~globalOuts, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer, \ratioBuf, ~ratioBuf, \trigRate, 1, \wideness, 1]);
}
)
~freqBufPointer.get(_.postln);
~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});
