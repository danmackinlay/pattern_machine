(
//initialisation
//Server.default = s = Server.internal;
Server.default = s = Server.local;
s.reboot;
StartUp.run;
)
(
SynthDef(\ps_infest_uni_host, {|in, i_sndbuffer, phaseout|
	var phase;
	phase = Phasor.ar(
		trig:0,
		rate: 1, // or if this could be a loaded file, BufRateScale.ir(sndbuffer)
		start: 0,
		end: BufFrames.ir(i_sndbuffer)
	);
	BufWr.ar(In.ar(in),
		bufnum: i_sndbuffer,
		phase:phase,
		loop:1
	);
	Out.kr(phaseout, A2K.kr(phase));
}).add;
SynthDef(\ps_infest_uni_parasite, {
	|out, gate=1,
	phasein, i_sndbuffer,
	windowSize=0.1,
	windowRandRatio=0.1,
	attack=0.05,
	amp=1.0,
	release=0.5|
	var phase, monosig, env;
	//This does what we want w/ gate set to 1 initially
	phase = Latch.kr(
		In.kr(phasein),
		gate
	) * BufFrames.ir(i_sndbuffer).reciprocal;
	env = EnvGen.kr(
		Env.asr(attackTime:attack, releaseTime:release),
		gate: gate,
		doneAction: 2
	);
	monosig = Warp1.ar(
		numChannels: 1,
		bufnum: i_sndbuffer,
		pointer: phase,
		interp: 2,
		windowSize: windowSize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);
	Out.ar(out, monosig);
}).add;
SynthDef(\ps_infest_poly_host, {
	|in, i_sndbuffer, phaseout|
	//have a stab at recording some stuff
	RecordBuf.ar(
		inputArray: In.ar(in),
		bufnum: i_sndbuffer,
		run:1,
		loop:0,
		doneAction:2
	);
}).add;
SynthDef(\ps_infest_poly_parasite, {
	|out, gate=1,
	i_sndbuffer,
	phase=0,
	windowSize=0.1,
	windowRandRatio=0.1,
	attack=0.05,
	amp=1.0,
	release=0.5|
	var monosig, env;
	env = EnvGen.kr(
		Env.asr(attackTime:attack, releaseTime:release),
		gate: gate,
		doneAction: 2
	);
	monosig = Warp1.ar(
		numChannels: 1,
		bufnum: i_sndbuffer,
		pointer: phase,
		interp: 2,
		windowSize: windowSize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);
	Out.ar(out, monosig);
}).add;
)
(
// uni_ -style
~recBuf = Buffer.alloc(s, s.sampleRate*60.0, 1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~phaseBus = Bus.control(s, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~host=Synth.new(\ps_infest_uni_host, [\in, ~in, \i_sndbuffer, ~recBuf, \phaseout, ~phaseBus], s);
~phaseBus.get;
~parasite=Synth.new(\ps_infest_uni_parasite, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, ~recBuf, \phasein, ~phaseBus], addAction:\addAfter, target:~rec);
~recBuf.plot;
)
(
// poly_ -style
~recBufs = Buffer.allocConsecutive(numBufs:10, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));
~recBuf = ~makehost.(0);
~recBuf.plot;
~makeparasite.(~recBuf);
)
