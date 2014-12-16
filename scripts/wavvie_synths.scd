//Grain candidates
//Warp1;
//GrainBuf
//TGrains (specified in seconds)

(
SynthDef.new(\ps_bufgrain_type_1__1x2, {
	arg gate=1,
	now=0.0,
	out=0,
	bufnum,
	pan=0,
	amp=1,
	timeago=0.0, //how far back from the end we wish to look
	sustainDur=1,
	pitchrate=1.0,
	posrate=1.0,
	grainsize=0.125,
	windowRandRatio=0.1,
	overlaps=2,
	interp=2,
	attack=0.1, release=0.1,
	tempo=1.0;

	var sig,
		env,
		baseTime,
		readTime,
		bufDur;
		
	timeago = timeago / tempo;
	sustainDur = sustainDur / tempo;
	grainsize = grainsize / tempo;
	
	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now, gate);
	//readTime = (baseTime - timeago +
	//	Phasor.ar(trig: gate, rate: SampleDur.ir*posrate, end: bufDur)
	//	).wrap(0, bufDur);
	//Or, since we can do this at control rate
	readTime = ((Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: 0
	) +
		(baseTime - timeago)
	)).wrap(0, bufDur);
	env = EnvGen.kr(
		Env.linen(
			attackTime: 0,
			sustainTime: sustainDur,
			releaseTime: release
			),
		levelScale: amp,
		doneAction: 2,
	);
	sig = Warp1.ar(
		numChannels: 1,
		bufnum: bufnum,
		pointer: (readTime * (bufDur.reciprocal)),
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize,
		overlaps: overlaps,
		windowRandRatio: windowRandRatio,
		mul: env
	);
	sig = OpHPF.ar(sig,
		100.0,
		iter: 1
	);
	Out.ar(out, Pan2.ar(sig, pan));
}, [
		nil, nil, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir
	]
).add;
SynthDef.new(\ps_bufgrain_type_2__1x2, {
	arg gate=1,
	now=0.0, //time - always in seconds, not beats
	out=0,
	bufnum,
	pan=0,
	amp=1,
	timeago=0.0, //how far back from the end we wish to look, in beats
	sustainDur=1,
	pitchrate=1.0,
	posrate=1.0,
	grainsize=0.125, // in beats
	overlaps=2,
	windowRandRatio=0.1,
	interp=2,
	attack=0.01,
	//release=0.1,
	lfobasef=1,
	lfomodf=2.5, //LFO freq, in beats
	lfomodamp=0.5,
	lfophase=0.25,//cos, lfomodamp-depending
	lfo2pos=0,
	lfo2amp=0,
	lfo2grain=0,
	lfo2pan=0,
	lfo2del=0,
	age2lfo=0,
	allpdelayratio=0.125,
	allpdecayratio=4,
	combed=0.5,
	tempo=1.0;

	var sig,
		env,
		baseTime,
		readTime,
		bufDur,
		lfo,
		age,
		deltime,
		dectime,
		combwet,
		combdry,
		lforangeScale;

	lfomodf = lfomodf * tempo;
	lfobasef = lfobasef * tempo;
	timeago = timeago / tempo;
	lforangeScale = (lfobasef.reciprocal).min(1);
	sustainDur = sustainDur / tempo;
	grainsize = grainsize / tempo;
	
	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now, gate);
	//TODO: LFOs on
	// pos
	// amp
	// pan,
	// grainsize,
	// and other LFOs
	// think also about optional LFO sync to overall rate
	// Also a scalar ramp that can be added to the LFO and poss other things
	age = Line.kr(start: 0, end: 1, dur: sustainDur);
	lfo = PMOsc.kr(carfreq: lfobasef,
		modfreq: lfomodf,
		pmindex: lfomodamp * pi * 2,
		modphase: lfophase * pi * 2,
	);

	readTime = ((Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: 0
	) +
		(baseTime - timeago)
	) +
		(lfo * lfo2pos * lforangeScale)
	).wrap(0, bufDur);
	env = EnvGen.kr(
		Env.perc(
			attackTime: attack,
			releaseTime: sustainDur,
			curve: -4.0,
			),
		levelScale: amp,
		doneAction: 2,
	);
	sig = Warp1.ar(
		numChannels: 1,
		bufnum: bufnum,
		pointer: (readTime * (bufDur.reciprocal)),
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize* (1+(lfo2grain * lfo)),
		overlaps: overlaps,
		windowRandRatio: windowRandRatio,
		mul: env * (1+(lfo2amp * lfo))
	);
	sig = OpHPF.ar(sig,
		100.0,
		iter: 1
	);
	//comb out window noise, at least somewhat
	combwet = (combed).sqrt;
	combdry = (1-(combed)).sqrt;
	sig = combdry*sig - DelayL.ar(sig, 1, grainsize*2, combwet.neg);
	deltime = allpdelayratio*grainsize;
	dectime = allpdecayratio*grainsize;
	sig = AllpassC.ar(sig,
		maxdelaytime: 1,
		delaytime: deltime+(lfo2del*(lfo+1)),
		decaytime: dectime);

	Out.ar(out, Pan2.ar(sig, pan));
}, [
		nil, nil, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir, \ir, \ir,
		\ir, \ir
	]
).add;
)