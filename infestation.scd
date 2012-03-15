(
//initialisation
//Server.default = s = Server.internal;
Server.default = s = Server.local;
s.reboot;
StartUp.run;
~recBuf = Buffer.alloc(s, s.sampleRate*60.0,1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~phaseBus = Bus.control(s, 1);
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
~rec=Synth.new(\ps_infest_recorder, [\in, ~in, \sndbuffer, ~recBuf, \phaseout, ~phaseBus], s);
~phaseBus.get;
)
