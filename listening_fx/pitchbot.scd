Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
//Todo:
// extend this to keep a bag of amplitudes to hand as well.
// Write a ring buffer of pitch guesses weighted by strength

SynthDef(\ps_pitch_writer, {
	|in, i_bufpointer, i_buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3|
	var trig, gate, pitch, certainty, amp, counter, write, buflen;
	buflen = BufFrames.ir(i_buffer)-1; //last sample gets filled with crap due to rude phase wrapping
	in = In.ar(in);
	#pitch, certainty = Tartini.kr(in);
	amp = Amplitude.kr(in);
	gate = (certainty>certthresh)*(amp>ampthresh);
	//trigger rate is modulated by the amount by which amp exceeeds threshold
	trig = Impulse.kr(baserate *
		amp.linlin(ampthresh, 1, 1, 1+ampscale)
	);
	trig = trig*gate;
	//NB following line does not wrap as advertised
	counter = Stepper.kr(trig, min:0, max:buflen);
	write = BufWr.kr(
		pitch, bufnum: i_buffer, 
		phase: (counter*trig) - (trig<1)
	);
	Poll.kr(trig, pitch, \pitchfound);
	Out.kr(i_bufpointer, counter);
}).add;
//Creates a bus full of random transpositions of the input pitches
SynthDef(\ps_pitch_spray, {
	|i_bufpointer, i_buffer, maxdel=50, out|
	var trig, gate, pitch, certainty, buflen;
	buflen = BufFrames.ir(i_buffer)-1;
	i_bufpointer = In.kr(i_bufpointer);
	pitch = BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			in: (i_bufpointer-(WhiteNoise.kr(mul:0.5,add:0.5)*maxdel)),
			lo:0, hi: buflen
		).poll(5,\phase),
		interpolation:1
	);
	pitch = Latch.kr(pitch, pitch); //latch pitches to reduce zeros before buffer is full
	Out.kr(out, pitch.max(0));
}).add;
~choosepitch = {|i_bufpointer, i_buffer, maxdel=50|
	 LastValue.kr(BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			in: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo: 0,
			hi: (BufFrames.ir(i_buffer)-1)
		),
		interpolation:1
	), inf).max(1);
};
SynthDef(\ps_flange_transpose, {
	|in, out, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratio=0.5|
	var pitch, base, numerator, denominator, delay, sig, env;
	//Linear envelope, coz it gets squared.
	base = ~choosepitch.(i_bufpointer, i_buffer, maxdel);
	numerator = ~choosepitch.(i_bufpointer, i_buffer, maxdel);
	denominator = ~choosepitch.(i_bufpointer, i_buffer, maxdel);
	pitch = Clip.kr(in: (i_ratio * base * numerator/denominator), lo:100, hi:10000);
	release=release*(pitch>100);
	attack=attack*(pitch>100);
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	in = In.ar(in,2)*env;
	sig  = Balance2.ar(in[0], in[1], Rand(lo:-1, hi:1));
	delay = pitch.reciprocal;
	sig = CombN.ar(
		in: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: release,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
SynthDef(\ps_flange_grain, {
	|in, out, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratio=0.5|
	var pitch, delay, sig, env;
	//Linear envelope, coz it gets squared.
	pitch = Clip.kr(in: (i_ratio * ~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:100, hi:10000);
	release=release*(pitch>100);
	attack=attack*(pitch>100);
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	in = In.ar(in,2)*env;
	sig  = Balance2.ar(in[0], in[1], Rand(lo:-1, hi:1));
	delay = pitch.reciprocal;
	sig = CombN.ar(
		in: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: release,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
SynthDef(\ps_flange_grain_bp, {
	|in, out, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratio=2, wideness=1|
	var pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	//Linear envelope, coz it gets squared.
	pitch = Clip.kr(in: (i_ratio * ~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (i_ratio * ~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	release=release*(pitch>minf)*(bpitch>minf);
	attack=attack*(pitch>minf)*(bpitch>minf);
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	in = In.ar(in,2)*env;
	sig  = Balance2.ar(in[0], in[1], Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		in: sig,
		freq: bpitch,
		bwr: wideness
	);
	delay = pitch.reciprocal;
	sig = CombN.ar(
		in: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: release,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
SynthDef(\delaylimit, {
	|out, delay=1|
	var in = In.ar(out, 2);
	in=LeakDC.ar(in);
	in = Limiter.ar(in, level: 0.5);
	in = DelayN.ar (in, maxdelaytime: 5, delaytime: delay);
	ReplaceOut.ar(out, in);
}).add;
/*
~chooseoffsetpitch = {|i_bufpointer, i_buffer, maxdel=50|
	 BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			in: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo:0,
			hi: BufFrames.ir(i_buffer)-1
		),
		interpolation:1
	).max(1);
};*/
//~analyseinput = Bus.newFrom(s.inputBus,0,1);
~analyseinput = Bus.newFrom(s.inputBus,2,1);
//~fxinput = Bus.newFrom(s.inputBus,0,2);
~fxinput = Bus.newFrom(s.inputBus,0,2);
~output = Bus.newFrom(s.outputBus,0,2);
~pitchbufpos = Bus.control(s, 1);
//~pitches = Bus.control(s, 1);
~buffer = Buffer.alloc(s, 1000);
~analysisgroup = Group.new(s);
~fxgroup = Group.after(~analysisgroup);
~fbgroup = Group.after(~fxgroup);
~masterfxgroup = Group.after(~fbgroup;);
~pitchwriter = Synth.new(\ps_pitch_writer, [\in, ~analyseinput, \i_bufpointer, ~pitchbufpos, \i_buffer, ~buffer, \ampthresh, 0.01, \baserate, 40], target: ~analysisgroup );
//~pitchwriter.free;
~masterfx = Synth.new(\delaylimit, [\out, ~output], target: ~masterfxgroup );
~fxinput
//~pitchsprayer = Synth.new(\ps_pitch_spray, [\i_bufpointer, ~pitchbufpos, \out, ~pitches, \i_buffer, ~buffer], target:~pitchwriter, addAction: \addAfter);
//~pitchsprayer.set(\maxdel, 10);
//Synth.new(\ps_flange_grain, [\in, ~fxinput, \out, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~buffer, \release, 5, \maxdel, 10], target:~fxgroup);
TempoClock.default.tempo = 1;
~basepatt = Pbind(
	\instrument, \ps_flange_grain_bp,
	\group, ~fxgroup,
	\in, ~fxinput,
	\out, ~output,
	\bufpointer, ~pitchbufpos,
	\buffer, ~buffer,
	\release, 5,
	\maxdel, 10,
	\ratio, 2,
	\wideness, Pexprand(0.1, 2.0)
);
~patt = Pbindf(~basepatt,
	\dur, Pexprand(0.05, 0.5),
	\release, Pkey(\dur)*5,
	\ratio, 2.pow(Prand([-1, 0, 1], inf))
);
~ppatt=~patt.play;
~ppatt.stop;
10.do({Synth.new(\ps_flange_grain_bp, [\in, ~fxinput, \out, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~buffer, \release, 5, \maxdel, 10], target:~fxgroup);});
~buffer.plot;
~pitchbufpos.get(_.postln);
~pitchbufpos;