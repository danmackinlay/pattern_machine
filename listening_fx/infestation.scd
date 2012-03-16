(
//initialisation
//Server.default = s = Server.internal;
Server.default = s = Server.local;
s.reboot;
StartUp.run;
)
(
SynthDef(\ps_infest_recorder, {|in, sndbuffer, phaseout|
	var phase;
	phase = Phasor.ar(
		trig:0,
		rate: 1, // or if this could be a loaded file, BufRateScale.ir(sndbuffer)
		start: 0,
		end: BufFrames.ir(sndbuffer)
	);
	BufWr.ar(In.ar(in),
		bufnum: sndbuffer,
		phase:phase,
		loop:1
	);
	Out.kr(phaseout, A2K.kr(phase));
}).add;
SynthDef(\ps_infest_pest_basic, {
	|out, gate=1,
	phasein, i_sndbuffer,
	windowSize=0.1,
	windowRandRatio=0.1|
	var phase, monosig;
	//This does what we want w/ gate set to 1 initially/
	phase = Latch.kr(
		In.kr(phasein),
		gate
	) * BufFrames.ir(i_sndbuffer).reciprocal;
	phase.poll(1, label: \grainphase);
	monosig = Warp1.ar(
		numChannels: 1,
		bufnum: i_sndbuffer,
		pointer: phase,
		interp: 2,
		windowSize: windowSize,
		overlaps: 2,
		windowRandRatio: windowRandRatio
	);
	Out.ar(out, monosig);
}).add;
~recBuf = Buffer.alloc(s, s.sampleRate*60.0, 1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~phaseBus = Bus.control(s, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~rec=Synth.new(\ps_infest_recorder, [\in, ~in, \sndbuffer, ~recBuf, \phaseout, ~phaseBus], s);
~phaseBus.get;
~pest=Synth.new(\ps_infest_pest_basic, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, ~recBuf, \phasein, ~phaseBus], addAction:\addAfter, target:~rec);
~recBuf.plot;
)
