

(
SynthDef.new(\findfreqs, {|in, rate = 10, gate=1, freqbuf, freqbufpointer|
	var hasFreq, freq, index, writing=0;
	//we presume freqbuf has 513 samples, and use 512. Why not?
	#freq, hasFreq = Pitch.kr(In.ar(in));
	writing = hasFreq* gate;
	index = Stepper.kr(Impulse.kr(rate) * writing, max: 511);
	BufWr.kr(
		freq,
		(index+(512*(1-writing))).min(512) //this last bit moves the read head to the end when there is no freq. Maybe I should do this at demand rate instead?
	);
	Out.kr(freqbufpointer, Gate.kr(index, hasFreq));
}).send(s);

//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate

//TODO: panning
//TODO: don't use freqs that haven't been written yet.
//TODO: create synthdefs for various numbers of voices than 20
//TODO: free voices in some nonlinear fashion to avoid obtrusiveness.
//TODO: respect nvoices
//TODO: respect numbuf
~maxvoices = 20;
SynthDef.new(\glimmergrains,
	{|in, out,
		trigrate=10,
		induty=0.5, playduty=0.5,
		reso=1,
		attack=0.01, decay=0.5,
		freqbuf, freqbuflen=10, freqbufpointer,
		numbuf, numbuflen=10, nvoices=10|
		var trigRamp, voices;
		in = In.ar(in);
		freqbufpointer = In.kr(freqbufpointer);
		trigRamp = LFSaw.kr(freq:trigrate, mul:0.5, add:0.5);
		voices = Array.fill(~maxvoices, {|i|
			var myRamp,inGate, outGate, inEnv, outEnv, myFreqLag, myFreq, myPan;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + (i * ~maxvoices.reciprocal));
			inGate = trigRamp < induty;
			outGate = trigRamp < playduty;
			inEnv = Linen.kr(inGate, attackTime: attack, releaseTime: decay);
			outEnv = Linen.kr(outGate, attackTime: attack, releaseTime: decay);
			//myFreq = TIRand.kr(lo:1,hi:3,trig:outGate);
			myFreqLag = TIRand.kr(lo:0, hi:freqbuflen, trig:outGate);
			myFreq = BufRd.kr(numChannels:1, bufnum:freqbuf,
				phase: Wrap.kr(freqbufpointer - myFreqLag, lo: 0, hi: 511),
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
	{|inbus, out|
		var in;
		in = SoundIn.ar(inbus);
		Amplitude.kr(in, releaseTime:1).poll(1, \inamp);
		Out.ar(out, in);}
).send(s);

~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send(s);
)

// indexing into a table
~pitchbuf = Buffer(s, 513, 1);
~ratiobuf = Buffer(s, 1024, 1);
// alloc and set the values
//pitches all 440Hz by default
s.listSendMsg( ~pitchbuf.allocMsg( ~pitchbuf.setnMsg(0, 440!513) ).postln );
//ratios all 1 by default.
s.listSendMsg( ~ratiobuf.allocMsg( ~ratiobuf.setnMsg(0, 1!513) ).postln );
//Now..
~globalOuts = Bus.new(\audio, 0, 2);
~indexbus = Bus.control(s,1);
~sourceIns = Bus.audio(s, 1);
~voxgroup = Group.new(s);
~fxgroup = Group.after(~voxgroup);
~outgroup = Group.after(~fxgroup);
~invox = Synth(\hardwarein, [\inbus, 0, \outbus, ~sourceIns], ~voxgroup);
//limiter, to avoid little accidents
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
s.volume.gui;
s.volume.volume= -20;
~listener = Synth.head(~fxgroup, \findfreqs, [\in, ~sourceIns, \freqbuf, ~pitchbuf, \freqbufpointer, ~indexbus]);
~fx = Synth.tail(~fxgroup, \glimmergrains, [\in, ~sourceIns, \out, ~globalOuts, \freqbuf, ~pitchbuf, \freqbufpointer, ~indexbus, \numbuf, ~ratiobus]);
~indexbus.get(_.postln);
