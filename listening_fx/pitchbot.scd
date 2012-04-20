Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
//Todo:
// extend this to keep a bag of amplitudes to hand as well.
// Write a ring buffer of pitch guesses weighted by strength

(
SynthDef(\ps_pitch_writer, {
	|in, i_bufpointer, i_buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3, dopoll=1|
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
	Poll.kr(trig*dopoll, pitch, \pitchfound);
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
SynthDef(\tempotrack, {|in, out, tempoout=(-1), beatout=(-1), vol=0.0, beepvol=0.0, lock=0|
	var fft, resample, fftbuffer;
	var trackb,trackh,trackq,tempo;
	var bsound,hsound,qsound, beep;
	fftbuffer = LocalBuf(1024, 1);

	in = In.ar(in);
	
	fft = FFT(fftbuffer, in);
	
	#trackb,trackh,trackq,tempo=BeatTrack.kr(fft, lock);
	
	tempo = Clip.kr(tempo, 0.1, 10);
	beep = SinOsc.ar(1000,0.0,Decay.kr(trackb,0.1));
	Out.kr(tempoout, tempo);
	Out.kr(beatout, tempo.reciprocal);
	Out.ar(out, Pan2.ar((vol*in)+(beepvol*beep), 0.0));
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
SynthDef(\ps_flange_grain_del_bp, {
	|delbuf, phasein, out, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, wideness=1|
	var in, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = LastValue.kr(bigdelay, inf);
	release = release*(pitch>minf)*(bpitch>minf);
	attack = attack*(pitch>minf)*(bpitch>minf);
	//Linear envelope, coz it gets squared.
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	in = DelTapRd.ar(buffer:delbuf, phase:In.kr(phasein), delTime:bigdelay)*env;
	sig  = Pan2.ar(in, Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		in: sig,
		freq: bpitch*i_ratiof,
		bwr: wideness
	);
	delay = (pitch*i_ratiod).reciprocal;
	sig = CombN.ar(
		in: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: release,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
//I get very occasional exploding peaks of doom in here, so I aggressively hunt and destroy
SynthDef(\antifbdelaylimit, {
	|out, delay=0.5, lookahead=0.05, mindelay=0.2|
	var in = In.ar(out, 2);
	in = Select.ar(CheckBadValues.ar(in, 0, 0), [in, DC.ar(0), DC.ar(0), DC.ar(0)]);
	in = LeakDC.ar(in);
	//Limiters are OK, but they don't stop the real nasty explosions
	in = in * (1-Trig1.kr(((in.abs)>2), 0.1));
	in = Limiter.ar(in, level: 0.5, dur:lookahead);
	in = DelayN.ar (in, maxdelaytime: 5, delaytime: Clip.kr((delay-lookahead), mindelay, 5);
	ReplaceOut.ar(out, in);
}).add;
SynthDef(\tee, {
	|out, out2|
	var in = In.ar(out, 2);
	//ReplaceOut.ar(out, in);
	Out.ar(out2, in);
}).add;
SynthDef(\injectfb, {
	|in, out, gain=0.5|
	in = InFeedback.ar(in, 2);
	Out.ar(out, in*gain);
}).add;
SynthDef(\delwrite, {|in, buffer, phaseout|
	var tapPhase;
	tapPhase = DelTapWr.ar(buffer, Mix.new(In.ar(in,2)));
	Out.kr(phaseout, tapPhase);
}).add;
)
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
//real input version
(
s.waitForBoot( fork {
	//~analyseinput = Bus.newFrom(s.inputBus,0,1);
	//~analyseinput = Bus.newFrom(s.inputBus,2,1);
	~analyseinput = Bus.audio(s,2);
	//~fxinput = Bus.newFrom(s.inputBus,0,2);
	~fxinput = Bus.newFrom(s.inputBus,0,1);
	~output = Bus.newFrom(s.outputBus,0,2);
	~fboutput = Bus.audio(s,2);
	~pitchbufpos = Bus.control(s, 1);
	~delbufpos = Bus.control(s, 1);
	~tempo = Bus.control(s, 1);
	~beat = Bus.control(s, 1);
	//~pitches = Bus.control(s, 1);
	~pitchbuffer = Buffer.alloc(s, 1000);
	~delbuffer = Buffer.alloc(s, 200000, 1);
	~analysisgroup = Group.new(s);
	s.sync;
	~fxgroup = Group.after(~analysisgroup);
	s.sync;
	~fbgroup = Group.after(~fxgroup);
	s.sync;
	~inputgroup = Group.before(~analysisgroup);
	s.sync;
	~masterfxgroup = Group.after(~fbgroup;);
	s.sync;
	~outputmasterfxgroup = Group.after(~masterfxgroup;);
	s.sync;
	~player = ~playFile.(out:~analyseinput, target: ~inputgroup, loop:1);
	~pitchwriter = Synth.new(\ps_pitch_writer, [\in, ~analyseinput, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \ampthresh, 0.01, \baserate, 40, \dopoll, 0], target: ~analysisgroup );
	~tempotracker = Synth.new(\tempotrack, [\in, ~analyseinput, \tempoout, ~tempo, \beatout, ~beat, \out, ~output, \vol, 0.2], target: ~analysisgroup );
	~mastersafetyfx = Synth.new(\antifbdelaylimit, [\out, ~output, \delay, ~beat.asMap, \lookahead, 0.1], target: ~outputmasterfxgroup );
	~delayin = Synth.new(\delwrite, [\in, ~fxinput, \buffer, ~delbuffer, \phaseout, ~delbufpos], target: ~fxgroup, addAction:\addToHead );
	//~tee = Synth.new(\tee, [\out, ~output, \out2, ~fboutput], target: ~fbgroup );
	//~fb = Synth.new(\injectfb, [\in, ~output, \out, ~fxinput], target: ~fxgroup, addAction:\addToHead );
	//~fb.set(\gain, 0.5);
	//~pitchsprayer = Synth.new(\ps_pitch_spray, [\i_bufpointer, ~pitchbufpos, \out, ~pitches, \i_buffer, ~pitchbuffer], target:~pitchwriter, addAction: \addAfter);
	//~pitchsprayer.set(\maxdel, 10);
	s.sync;
	~basepatt = Pbind(
		\out, ~output, 
		\instrument, \ps_flange_grain_del_bp,
		\group, ~fxgroup,
		\delbuf, ~delbuffer,
		\phasein, ~delbufpos,
		\bufpointer, ~pitchbufpos,
		\buffer, ~pitchbuffer,
		\delbuffer, ~delbuffer,
		\release, 5,
		\maxdel, 10,
		\ratiod, 2,
		\ratiof, 2,
		\wideness, Pexprand(0.1, 0.3)
	);
	~patt = Pbindf(~basepatt,
		\dur, 2.pow(Prand((-4..-1), inf)),
		\release, Pkey(\dur)*2.pow(Prand((1..4), inf)),
		\ratiod, 2.pow(Prand((-2..1), inf))*Prand([4/3, 5/4, 1], inf),
		\ratiof, 2.pow(Prand((-2..1), inf))*Prand([4/3, 5/4, 1], inf),
		\bigdelay, ~tempo.asMap
	);
	~ppatt=~patt.play;
	~tempoupdate=Routine({
		loop {~tempo.get({|tempo|
			TempoClock.default.tempo = tempo.max(0.1);
			["tempo is now", tempo].postln;
		});
		1.yield;}
	}).play(TempoClock.new);
});
)
~tempo.get;
~beat.get;
(
	~ppatt.stop;
	~player.free;
	~pitchwriter.free;
	~tempotracker.free;
	~mastersafetyfx.free;
	~delayin.free;
	~tee.free;
	~fb.free;
	~tempoupdate.stop;
)
Synth.new(\ps_flange_grain_del_bp, [\delbuf, ~delbuffer, \phasein, ~delbufpos, \out, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \release, 25, \maxdel, 10], target:~fxgroup).trace;
10.do({Synth.new(\ps_flange_grain_del_bp, [\delbuf, ~delbuffer, \phasein, ~delbufpos, \out, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \release, 25, \maxdel, 10, \bigdelay, {0.1.rrand(1);}], target:~fxgroup);});
~pitchwriter.set(\dopoll, 0);
~pitchwriter.trace;
~pitchwriter.trace;
~delbufpos.get;
~ppatt.stop;
~pitchbuffer.plot;
~pitchbufpos.get(_.postln);
~pitchbufpos;
~tempotracker.set(\vol, 0.6);
