Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
~input = Bus.newFrom(s.inputBus,0,1);
~pitchbufpos = Bus.control(s, 1);
~buffer = Buffer.alloc(s, 10000);
SynthDef(\ps_pitch_writer, {
	|in, out, buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3, buflen=10000|
	var trig, gate, pitch, certainty, amp, counter, write;
	in = In.ar(in);
	#pitch, certainty = Tartini.kr(in);
	amp = Amplitude.kr(in);
	trig = Impulse.kr(baserate*(1+(amp*ampscale)));
	gate = (certainty>certthresh)*(amp>ampthresh);
	trig = trig*gate;
	counter = Stepper.kr(trig, max:buflen-1);
	write = Dbufwr(counter, pitch, buffer, counter);
	Poll.kr(trig, pitch, \p);
	Poll.kr(trig, counter, \c);
	Demand.kr(trig, 0, write); // write on trigger
	Out.kr(out, counter);
}).add;
Synth.new(\ps_pitch_writer, [\in, ~input, \out, ~pitchbufpos, \buffer, ~buffer]);
