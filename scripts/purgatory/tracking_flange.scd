(
//That this works defies my understanding of Environment w/regard to scope.
//i guess forking gets you a new environment per default?
~fx = \foo;
~mainOut = \foo;
~fxGroup = \foo;
~synthGroup = \foo;
~synthBus = \foo;
~masterGroup = \foo;
~limiter = \foo;
fork {
	//s = Server.internal;
	s = Server.local;

	SynthDef.new(\sawgrain, { |out=0, freq = 440, amp = 0.2, sustain = 1, headroom=400, rq=0.1|
		var	sig, env;
		env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
		sig = RLPF.ar(Saw.ar(freq, amp), freq + (env * headroom), rq) * env;
		Out.ar(out, sig ! 2);	// sig ! 2 is the same as [sig, sig]

	}).add;

	//TODO: add in spring constrints w/regard to central frequency.
	//TODO: add in hard clipping to avoid mishaps
	//TODO: add in dust noise to anneal out of local maxima
	//TODO: how do you multichannel this?
	//TODO: make this a send effect so they don't all feed in to one another.
	//TODO: work out how to make the higher delay not be favoured by reaching its peak more rapidly
	SynthDef.new(\rezofloss,
		{ |in, out=0, freq = 220,
			sideFreq=10,
			range=0.9, decay=0.5,
			lag=0.1, rate=10.0,
			offPeakGain=0, offPeakLag=0.2,
			gate = 1|
		var sigIn, sigOut, reference, offsetFreq, currentFreq, lower, middle, higher, velocity, env, offPeak, delta, peakGain;
		in.poll(1, \i);
		velocity = Lag.kr(LocalIn.kr(1), lag).poll(1, \v);
		offsetFreq = Decay.kr(velocity, lag).poll(1, \off);
		currentFreq = (freq + offsetFreq).max(10+sideFreq).min(8000-sideFreq).poll(1, \c);//Clip.kr NaNs out for me
		sigIn = In.ar(in);
		sigOut = LeakDC.ar(CombL.ar(sigIn, 0.1, currentFreq.reciprocal, decay));
		reference = Amplitude.kr(DelayN.ar(sigIn, 0.1, currentFreq.reciprocal))+ 0.0001;
		lower = Amplitude.kr(LeakDC.ar(CombL.ar(sigIn, 0.1, (currentFreq-sideFreq).reciprocal, decay)))/reference.poll(1, \l);
		middle = (Amplitude.kr(sigOut)/reference).poll(1, \m);
		higher = (Amplitude.kr(LeakDC.ar(CombL.ar(sigIn, 0.1, (currentFreq+sideFreq).reciprocal, decay)))/reference).poll(1, \h);
		//now we know whether our local frequency is most resonant, or whether the sidebands are more resonant
		offPeak = (lower<middle) * (higher<middle);
		delta = rate * ((higher-lower).sign) * ((higher-middle).max(lower-middle)).poll(1, \delta) ;// /(ControlRate.ir);
		//spring constraints here
		LocalOut.kr(offPeak*delta);
		peakGain = Lag.kr(Select.kr(offPeak, [1, offPeakGain]), offPeakLag);//mute when in transit
		env = EnvGen.kr(Env.asr(0.01, 1.0, 0.1), gate, doneAction: 2) * peakGain;
		Out.ar(out, (sigOut * env) ! 2);	// sig ! 2 is the same as [sig, sig]
	}).add;

	SynthDef.new(\stereolimiter, {|out| ReplaceOut.ar(out, Limiter.ar(In.ar(out, 2))); }).add;
	s.sync;

	~mainOut = Bus.new(\audio, 0, 2);
	~synthBus = Bus.audio(s, 2);
	~synthGroup = Group.new(s);
	s.sync;
	~fxGroup = Group.after(~synthGroup);
	s.sync;
	~masterGroup = Group.after(~fxGroup);
	s.volume.volume(-10);
	s.sync;

	p = Pbind(
			\out, ~synthBus,
			\instrument, \sawgrain,
			\midinote, Pseq([66, 69, 80, 50], inf),
			\dur, Pseq([0.75, 0.25, 0.25, 0.25, 0.5]/4, inf),
			//\legato, 0.5, //no sustain!
			\amp, 0.5, //\detune, 1.005,
			\group, ~synthGroup
		).play(quant: 1);

	s.sync;

	~fx = Synth.new(\rezofloss, [\in, ~synthBus, \out, ~mainOut, \freq, 90.midicps], ~fxGroup).play;
	~limiter = Synth.new(\stereolimiter, [\out, ~mainOut], ~masterGroup);
};
)

~fx.set(\gate, 0);
~fx.get(\gate);
~fx.set(\freq, 88.1.midicps);
~fx.set(\sideFreq, 20);
~fx.set(\rate, 100);
~synthBus.scope;
s.volume.volume(-20);
~mainOut.scope;

//Does Comb include dry information or only wet?
{ var dry, wet, ampwetdry, ampwet, ampdry; dry = Decay.ar(Impulse.ar(10,0), 0.2, WhiteNoise.ar); wet=CombL.ar(dry, 0.01, 0.1, 3); ampwet=Amplitude.kr(wet); ampwetdry = Amplitude.kr(wet-dry); ampdry = Amplitude.kr(dry); Out.kr(0, [ampdry, ampwet, ampwetdry, (ampwetdry-ampwet)]) }.scope;
//Juding by amplitudes, seems that it does not - strictly wet only. which is what we want.