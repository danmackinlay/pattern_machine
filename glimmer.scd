

(
SynthDef.new(\findfreqs, {|in, rate = 10, freqbuf|
	var hasFreq, freq;
	#freq, hasFreq = Pitch.kr(In.ar(in));
	SendTrig.kr(
		Impulse.kr(rate)* hasFreq,
		value: freq
	);
	}).send(s);
)

//So, should this little guy voice a whole bunch of flange frequencies at a given polyphony with known rate? Should polyphony be handled client-side or server? I feel server, but am not sure how to manage rate then. Anyway, pan, pitch etc should be randomised
// indexing into a table
~startpitches = [ 200, 300, 400, 500, 600, 800 ];
~pitchbuf = Buffer(s,t.size,1);

// alloc and set the values
s.listSendMsg( b.allocMsg( b.setnMsg(0, t) ).postln );

//TODO: panning


SynthDef.new(\glimmergrains,
	{|in, out, trigrate=10, induty=0.5, playduty=0.5, reso=1, attack=0.01, decay=0.5, freqbuf, freqbuflen, numbuf, numbuflen, denombuf, denombuflen, nvoices=10, maxvoices=10|
		var trigRamp, voices;
		in = In.ar(in);
		trigRamp = LFSaw.kr(freq=trigrate, mul:0.5, add:0.5);
		voices = Array.fill(maxvoices, {|i| 
			var myRamp,inGate, outGate, inEnv, outEnv, myFreq, myPan;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + (i * numVoices.recpirocal));
			inGate = trigRamp < induty;
			outGate = trigRamp < outduty;
			inEnv = Linen.kr(inGate, attackTime: attack, releaseTime: decay);
			outEnv = Linen.kr(outGate, attackTime: attack, releaseTime: decay);
			myFreq = TIRand.kr(lo:1,hi:3,trig:outGate);
			CombL.ar(inEnv*in, 0.1, myFreq.reciprocal, reso)*outEnv;
		;});
		Out.ar(Mix.ar(voices));
	}
);

