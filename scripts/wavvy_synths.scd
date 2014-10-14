//TODO: markovity
//TODO: think about a less stupid modulation architecture, w/nice LFOs on pos, amp, pan, grainsize, and other LFOs
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
	interp=4,
	attack=0.1, release=0.1;

	//Grain candidates
	//Warp1;
	//GrainBuf
	//TGrains (specified in seconds)

	var sig,
		env,
		baseTime,
		readTime,
		bufDur;
	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now, gate);
	//readTime = (baseTime - timeago +
	//	Phasor.ar(trig: gate, rate: SampleDur.ir*posrate, end: bufDur)
	//	).wrap(0, bufDur);
	//Or, since we can do this at control rate
	readTime = Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: (baseTime - timeago).wrap(0, bufDur)
	);
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
		pointer: readTime * (bufDur.reciprocal),
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)