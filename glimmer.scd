

(
SynthDef.new(\findfreqs, {|in, rate = 10, gate=1, freqBuf, freqBufPointer|
	var hasFreq, freq, index, writing=0;
	//we presume freqBuf has 513 samples, and use 512. Why not?
	#freq, hasFreq = Pitch.kr(In.ar(in));
	Amplitude.kr(In.ar(in), releaseTime:1).poll(10, \inamp);
	writing = hasFreq* gate;
	index = Stepper.kr(Impulse.kr(rate) * writing, max: 511);
	BufWr.kr(
		freq,
		(index+(512*(1-writing))).min(512) //this last bit moves the read head to the end when there is no freq. Maybe I should do this at demand rate instead?
	);
	freq.poll(10, \freq);
	Out.kr(freqBufPointer, Gate.kr(index, hasFreq));
}).send(s);

//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate

//TODO: panning
//TODO: don't use freqs that haven't been written yet.
//TODO: create synthdefs for various numbers of voices than 20
//TODO: free voices in some nonlinear fashion to avoid obtrusiveness.
//TODO: respect nVoices
//TODO: respect numBuf

~maxVoices = 20;
SynthDef.new(\glimmergrains,
	{|in, out,
		trigRate=10,
		inDuty=0.5, playDuty=0.5,
		reso=1,
		attack=0.01, decay=0.5,
		freqBuf, freqBufLength=10, freqBufPointer,
		numBuf, numBufLength=10, nVoices=10|
		var trigRamp, voices;
		in = In.ar(in);
		freqBufPointer = In.kr(freqBufPointer);
		trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
		voices = Array.fill(~maxVoices, {|i|
			var myRamp,inGate, outGate, inEnv, outEnv, myFreqLag, myFreq, myPan;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + (i * ~maxVoices.reciprocal));
			inGate = trigRamp < inDuty;
			outGate = trigRamp < playDuty;
			inEnv = Linen.kr(inGate, attackTime: attack, releaseTime: decay);
			outEnv = Linen.kr(outGate, attackTime: attack, releaseTime: decay);
			//myFreq = TIRand.kr(lo:1,hi:3,trig:outGate);
			myFreqLag = TIRand.kr(lo:0, hi:freqBufLength, trig:outGate);
			myFreq = BufRd.kr(numChannels:1, bufnum:freqBuf,
				phase: Wrap.kr(freqBufPointer - myFreqLag, lo: 0, hi: 511),
				interpolation:1).max(10);
			CombL.ar(in: inEnv*in,
				maxdelaytime: 0.1,
				delaytime: myFreq.reciprocal,
				decaytime: reso,
				mul:outEnv);
		});
		Out.ar(out, LeakDC.ar(Mix.ar(voices)));
	}	
).send(s);

SynthDef.new(\hardwarein,
	{|in, out|
		in = SoundIn.ar(in);
		// Amplitude.kr(in, releaseTime:1).poll(1, \inamp);
		Out.ar(out, in);}
).send(s);

~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send(s);
)

(
// indexing into a table
~freqBuf = Buffer(s, 513, 1);
~ratioBuf = Buffer(s, 1024, 1);
// alloc and set the values
//pitches all 440Hz by default
s.listSendMsg( ~freqBuf.allocMsg( ~freqBuf.setnMsg(0, 440!513) ).postln );
//ratios all 1 by default.
s.listSendMsg( ~ratioBuf.allocMsg( ~ratioBuf.setnMsg(0, 1!513) ).postln );
//Now..
~globalOuts = Bus.new(\audio, 0, 2);
~freqBufPointer = Bus.control(s, 1);
~sourceIns = Bus.audio(s, 1);
~voxGroup = Group.new(s);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);
//read hardware in at head of ~voxGroup
~inVox = Synth(\hardwarein, [\in, 0, \out, ~sourceIns], ~voxGroup);
//limiter, to avoid little accidents.
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
//s.volume.gui;
s.volume.volume= -20;
~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
~fx = Synth.tail(~fxGroup, \glimmergrains, [\in, ~sourceIns, \out, ~globalOuts, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer, \numBuf, ~ratioBuf]);
~freqBufPointer.get(_.postln);
)