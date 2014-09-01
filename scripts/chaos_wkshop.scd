Server.default=s=Dan.serverboot(prox:\local, device:\builtin);
~state=nil;
(
var state = ~state ?? {()};
var samplebuf, channel;
topEnvironment.put(\state, state);
fork {
	state.use({
	~tempo = 120;
	~clock = TempoClock.default.tempo_(~tempo /60.0);
	~looptempo = 120;
	~loopbeatlen = 60.0/~looptempo;
	~loopbeats = 8;
	~delta = 1;
	~degree = 1;
	~foo = 5;
	~skipdenom = 16;
	~skipmaxnum = 0;
	~reseed = true;
	~lambda = 2.0;
	~density = 1.0;
	~intensity = 1.0;
	~baseoffset = 5;// in seconds
	~quant = 1/4;
	~quantstrength = 0.0;
	~samppath = topEnvironment.at(\sczamples) +/+ "CONCERTOFORCLARINETP2-solo.wav";
	~buf = Buffer.alloc(s, 44100*60, 1);
	CmdPeriod.doOnce({ ~buf.free });
	s.sync;
	~buf.readChannel(~samppath, channels:[0]);

	SynthDef.new(\ps_buf_play__1x1, {
		arg	out=0,
		bufnum,
		amp=1, gate=1,
		attack=0.01, decay=0.1, sustain=1.0, release=0.1,
		offset=0;

		var sig, env;
		env = EnvGen.kr(
			Env.adsr(
				attackTime: attack,
				decayTime: decay,
				sustainLevel: sustain,
				releaseTime: release),
			gate: gate,
			levelScale:amp,
			doneAction: 2);
		sig = PlayBuf.ar(
				1,
				bufnum,
				trigger: gate,
				rate: BufRateScale.kr(bufnum),
				startPos: BufSampleRate.kr(bufnum)*offset,
		)* env;
		Out.ar(out, sig);
	}).add;
	~pat = Pbind(
		\instrument, \ps_buf_play__1x1,
		\bufnum, ~buf,
		\legato, Pfunc({~density}),
		\dur, PexpR(lambda:Pfunc({~intensity})),
		\amp, 1,
		\sustain, Pfunc({~density}),
	);
	~pat = Pquantize(~pat,
		quant: Pfunc({~quant}),
		strength: Pfunc({~quantstrength}),
		barlen: 8);
	~pat = (Pbind(
		\offset, Pfunc({~baseoffset}) + (
			Plocaltime(wrap:Pfunc({~loopbeats}))
			+ (Pwhite(0, Pfunc({~skipmaxnum}))/Pfunc({~skipdenom}))
			* Pfunc({~loopbeatlen})
		),
	)<> ~pat).trace;
	~str = ~pat.trace.play(~clock);
})};
state;
)
~state.loopbeatlen;
~state.skipmaxnum=32;
~state.density=3;
~state.intensity=15;
