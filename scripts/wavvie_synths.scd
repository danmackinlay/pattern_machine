//TODO: make most params init-rate
//Grain candidates
//Warp1;
//GrainBuf
//TGrains (specified in seconds)


(
SynthDef.new(\ps_bufgrain_type_1__1x2, {
	arg out=0,
	bufnum,
	timeago=0.0, //how far back from the end we wish to look
	now=0.0,
	sustainDur=1,
	pitchrate=1.0,
	posrate=1.0,
	grainsize=0.1,
	windowRandRatio=0.1,
	pan=0, amp=1, gate=1,
	interp=2,
	attack=0.1, release=0.1,
	debugrate=0;

	var sig,
		env,
		baseTime,
		readTime,
		bufDur;
	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now.poll(debugrate, \now), gate);
	//readTime = (baseTime - timeago +
	//	Phasor.ar(trig: gate, rate: SampleDur.ir*posrate, end: bufDur)
	//	).wrap(0, bufDur);
	//Or, since we can do this at control rate
	readTime = Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: (baseTime - timeago).poll(debugrate, \unwrappedreadtime).wrap(0, bufDur)
	).poll(debugrate, \readtime);
	env = EnvGen.kr(
		Env.linen(
			attackTime: 0,
			sustainTime: sustainDur,
			releaseTime: release
			),
		levelScale: 1,
		doneAction: 2,
	);
	sig = Warp1.ar(
		numChannels: 1,
		bufnum: bufnum,
		pointer: readTime * (bufDur.reciprocal).poll(debugrate, \pointer);,
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
SynthDef.new(\ps_bufgrain_type_2__1x2, {
	arg out=0,
	bufnum,
	timeago=0.0, //how far back from the end we wish to look
	now=0.0,
	sustainDur=1,
	pitchrate=1.0,
	posrate=1.0,
	grainsize=0.1,
	windowRandRatio=0.1,
	pan=0, amp=1, gate=1,
	interp=2,
	attack=0.1, release=0.1,
	lfobasef=1,
	lfomodf=2.5,
	lfomodamp=0.5,
	lfophase=0.25,//cos, lfomodamp-depending
	lfo2pos=0,
	lfo2amp=0,
	lfo2grain=0,
	lfo2pan=0,
	age2lfo=0,
	debugrate=0;

	var sig,
		env,
		baseTime,
		readTime,
		bufDur,
		lfo,
		age;

	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now.poll(debugrate, \now), gate);
	//TODO: LFOs on
	// pos
	// amp
	// pan,
	// grainsize,
	// and other LFOs
	// think also about optional LFO sync to overall rate
	// Also a scalar ramp that can be added to the LFO and poss other things
	age = Line.kr(start: 0, end: 1, dur: sustainDur + release);
	lfo = PMOsc.kr(carfreq: lfobasef,
		modfreq: lfomodf,
		pmindex: lfomodamp * pi * 2,
		modphase: lfophase * pi * 2);

	readTime = (Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: (baseTime - timeago).poll(debugrate, \unwrappedreadtime)

	) + (lfo * lfo2pos)).wrap(0, bufDur) .poll(debugrate, \readtime);

	env = EnvGen.kr(
		Env.linen(
			attackTime: 0,
			sustainTime: sustainDur,
			releaseTime: release
			),
		levelScale: 1,
		doneAction: 2,
	);
	sig = Warp1.ar(
		numChannels: 1,
		bufnum: bufnum,
		pointer: readTime * (bufDur.reciprocal).poll(debugrate, \pointer);,
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize* (1+(lfo2grain * lfo)),
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env * (1+(lfo2amp * lfo))
	);

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)