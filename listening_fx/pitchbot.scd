Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
~input = Bus.newFrom(s.inputBus,0,1);
~pitchbufpos = Bus.control(s, 1);
~pitches = Bus.control(s, 1);
~buffer = Buffer.alloc(s, 1000);
//Todo extend this to keep a bag of amplitudes to hand too.
//Write a ring buffer of pitch guesses weighted by strength
SynthDef(\ps_pitch_writer, {
	|in, bufpointer, i_buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3|
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
	counter = Stepper.kr(trig, max:buflen);
	write = BufWr.kr(
		pitch, bufnum: i_buffer, 
		phase: (counter*trig) - (trig<1)
	);
	Out.kr(bufpointer, counter);
}).add;
/*
//Reads a random transposed pitch transposition off the ring buffer. Pretty broken atm.
SynthDef(\ps_pitch_reader, {
	|bufpointer, buffer, maxdel=50|
	var trig, gate, pitch, read, buflen;
	buflen = BufFrames.ir(i_buffer);
	bufpointer = In.kr(bufpointer);
	read = Dbufrd(buffer, Diwhite(bufpointer-maxdel, bufpointer, inf));
	Poll.kr(trig, pitch, \p);
	Poll.kr(trig, counter, \c);
	Demand.kr(trig, 0, write); // write on trigger
}).add;
*/
//Creates a bus full of random transpositions of the input pitches
SynthDef(\ps_pitch_spray, {
	|bufpointer, i_buffer, out, maxdel=50|
	var trig, gate, pitch, certainty, buflen;
	buflen = BufFrames.ir(i_buffer)-1;
	bufpointer = In.kr(bufpointer);
	pitch = BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			in: (bufpointer-(WhiteNoise.kr(mul:0.5,add:0.5)*maxdel)),
			lo:0, hi: buflen
		).poll(5,\phase),
		interpolation:1
	);
	pitch = Latch.kr(pitch, pitch); //latch pitches to reduce zero before buffer is full
	Out.kr(out, pitch.max(0));
}).add;
~pitchwriter = Synth.new(\ps_pitch_writer, [\in, ~input, \bufpointer, ~pitchbufpos, \i_buffer, ~buffer]);
/*Synth.new(\ps_pitch_reader, [\in, ~input, \out, ~pitchbufpos, \buffer, ~buffer]);*/
~pitchsprayer.free;
~pitchsprayer = Synth.new(\ps_pitch_spray, [\bufpointer, ~pitchbufpos, \out, ~pitches, \i_buffer, ~buffer], target:~pitchwriter, addAction: \addAfter);
~pitchsprayer.set(\maxdel, 10);
~buffer.plot;
~pitches.get(_.postln);
~pitchbufpos.get(_.postln);