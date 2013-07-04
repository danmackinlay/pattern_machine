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
		freqBus,
		ratioBuf,
		intensity=1.0,
		feedbackGain = 0.5, feedbackLen=0.1|
		var trigRamp, voices, mixedIn, outChannels, feedback, freqEst;
		inbus = In.ar(inbus, 2);
		feedback = DelayL.ar(
			in: LocalIn.ar(2),
			maxdelaytime: 1.0,
			delaytime: feedbackLen-ControlRate.ir.reciprocal,
			mul:feedbackGain) ;
		mixedIn = Mix.new(inbus+feedback);
		//poor-man's shared ring buffer
		freqEst = In.kr(freqBus);
		trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
		voices = Array.fill(maxVoices, {|i|
			var myRamp;
			var gate, env;
			var myDelayFreq, myFilterFreq, myPan;
			var phase, pan, threshold;
			var ratioPointerFilt, ratioPointerDelay;
			var ratioFilt, ratioDelay;
			var localFreq;
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
			localFreq = Latch.kr(freqEst, gate);
			myDelayFreq = (localFreq* ratioFilt).max(10);
			myFilterFreq = (localFreq* ratioFilt).max(80);
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

SynthDef.new(\findfreq, {|inbus, outbus|
	var hasFreq, freq;
	//we presume freqBuf has 513 samples, and use 512. Why not?
	#freq, hasFreq = Pitch.kr(
		HPF.ar(HPF.ar(
			Mix.new(
				In.ar(inbus, 2)
			),
			freq:100), freq:100
		),
		execFreq: ControlRate.ir
	);

	Out.kr(outbus, Gate.kr(freq, hasFreq).max(10));
}).add;
)

(
fork {
	~ratioBuf = Buffer(s, 512, 1);
	// alloc and set the values
	//ratios all 1 by default.
	s.sync;
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
	~listener = Synth.head(~fxGroup, \findfreq, [\inbus, ~sourceIns, \outbus, ~freqBus]);
	~fx = Synth.tail(~fxGroup, \glimmergrains, [\inbus, ~sourceIns, \outbus, ~globalOuts, \freqBus, ~freqBus, \ratioBuf, ~ratioBuf, \trigRate, 1, \wideness, 1]);
}
)
~freqBus.get(_.postln);
~sourceIns.scope