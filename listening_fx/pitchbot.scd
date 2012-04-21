Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);


//Todo:
// extend this to keep a bag of amplitudes to hand as well.
// Write a ring buffer of pitch guesses weighted by strength

(
SynthDef(\ps_pitch_writer, {
	|in, i_bufpointer, i_buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3, pitchthresh=100, dopoll=1|
	var trig, gate, pitch, certainty, amp, counter, write, buflen;
	buflen = BufFrames.ir(i_buffer)-1; //last sample gets filled with crap due to rude phase wrapping
	in = In.ar(in);
	#pitch, certainty = Tartini.kr(in);
	amp = Amplitude.kr(in);
	gate = (certainty>certthresh)*(amp>ampthresh)*(pitch>pitchthresh);
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
~trackpitch = {|i_bufpointer, i_buffer, maxdel=50|
	 BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			in: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo: 0,
			hi: (BufFrames.ir(i_buffer)-1)
		),
		interpolation:1
	).max(1);
};
SynthDef(\ps_flange_chorister_del_bp, {
	|delbuf, phasein, out, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1|
	var in, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(in: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
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
		decaytime: decaytime,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
SynthDef(\ps_flange_chorister_del_bp_compand, {
	|delbuf, phasein, out, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1, thresh=0.001, slopeAbove=0.1|
	var in, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(in: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
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
		decaytime: decaytime,
		mul:env);
	sig = Compander.ar(sig, sig, thresh: thresh, slopeAbove:slopeAbove, mul: (thresh+((1-thresh)*slopeAbove)).reciprocal);
	sig = sig*env;
	Out.ar(out, sig);
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
	|delbuf, phasein, out, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1|
	var in, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
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
		decaytime: decaytime,
		mul:env);
	sig = sig*env;
	Out.ar(out, sig);
}).add;
SynthDef(\ps_flange_grain_del_bp_compand, {
	|delbuf, phasein, out, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1, thresh=0.001, slopeAbove=0.1|
	var in, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(in: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
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
		decaytime: decaytime,
		mul:env);
	sig = Compander.ar(sig, sig, thresh: thresh, slopeAbove:slopeAbove, mul: (thresh+((1-thresh)*slopeAbove)).reciprocal);

	sig = sig*env;
	Out.ar(out, sig);
}).add;
//I get very occasional exploding peaks of doom in here, so I aggressively hunt and destroy
SynthDef(\antifbdelaylimit, {
	|out, pregain=1.0, delay=0.5, lookahead=0.05, mindelay=0.2|
	var in = In.ar(out, 2);
	in = Select.ar(CheckBadValues.ar(in, 0, 0), [in, DC.ar(0), DC.ar(0), DC.ar(0)]);
	in = LeakDC.ar(in, mul:pregain);
	//Limiters are OK, but they don't stop the real nasty explosions
	in = in * (1-Trig1.kr(((in.abs)>2), 0.1));
	in = Limiter.ar(in, level: 0.5, dur:lookahead);
	in = DelayN.ar (in, maxdelaytime: 5, delaytime: Clip.kr((delay-lookahead), mindelay, 5));
	ReplaceOut.ar(out, in);
}).add;
SynthDef(\ducker, {
	|out, sidechain, threshold=0.4, slopeAbove=0.1, clampTime=0.01, relaxTime=0.3|
	var in = In.ar(out, 2);
	sidechain = Mix.new(In.ar(sidechain, 2));
	in = Compander.ar(in, sidechain, slopeAbove: slopeAbove, clampTime:clampTime, relaxTime:relaxTime);
	ReplaceOut.ar(out, in);
}).add;
SynthDef(\reverb, {
	|out,mix=1, room=0.9, damp=0.4|
	var in = In.ar(out, 2);
	in = FreeVerb2.ar(in[0], in[1], mix:mix, room:room, damp:damp);	ReplaceOut.ar(out, in);
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
//chorister version
(
s.waitForBoot( fork {
	//~log = LogFile.global;
	//~analyseinput = Bus.newFrom(s.inputBus,0,1);
	//~analyseinput = Bus.newFrom(s.inputBus,2,1);
	~analyseinput = Bus.audio(s,2);
	//~fxinput = Bus.newFrom(s.inputBus,0,2);
	~fxinput = Bus.newFrom(s.inputBus,0,1);
	//~fxinput = Bus.newFrom(s.inputBus,8,2);
	~output = Bus.newFrom(s.outputBus,0,2);
	~fboutput = Bus.audio(s,2);
	~pitchbufpos = Bus.control(s, 1);
	~delbufpos = Bus.control(s, 1);
	~tempobus = Bus.control(s, 1);
	~tempo = 2;
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
	~player = ~playFile.(out:~analyseinput, target: ~inputgroup, loop:1, );
	~pitchwriter = Synth.new(\ps_pitch_writer, [\in, ~analyseinput, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \ampthresh, 0.01, \baserate, 40, \dopoll, 0], target: ~analysisgroup );
	~tempotracker = Synth.new(\tempotrack, [\in, ~analyseinput, \tempoout, ~tempobus, \beatout, ~beat, \out, ~output, \vol, 0.0], target: ~analysisgroup );
	~mastersafetyfx = Synth.new(\antifbdelaylimit, [\out, ~output, \delay, ~beat.asMap, \lookahead, 0.1, \pregain, 3], target: ~masterfxgroup );
	~ducker = Synth.new(\ducker,  [\out, ~output, \sidechain, ~fxinput, \threshold, 0.1, \slopeAbove, 0], target: ~outputmasterfxgroup);
	~reverb = Synth.new(\reverb,  [\out, ~output, \mix, 0.5, \room, 0.1, \damp, 0.3], target: ~outputmasterfxgroup, addAction: \addToTail);
	~delayin = Synth.new(\delwrite, [\in, ~fxinput, \buffer, ~delbuffer, \phaseout, ~delbufpos], target: ~fxgroup, addAction:\addToHead );
	//~tee = Synth.new(\tee, [\out, ~output, \out2, ~fboutput], target: ~fbgroup );
	//~fb = Synth.new(\injectfb, [\in, ~output, \out, ~fxinput], target: ~fxgroup, addAction:\addToHead );
	//~fb.set(\gain, 0.5);
	//~pitchsprayer = Synth.new(\ps_pitch_spray, [\i_bufpointer, ~pitchbufpos, \out, ~pitches, \i_buffer, ~pitchbuffer], target:~pitchwriter, addAction: \addAfter);
	//~pitchsprayer.set(\maxdel, 10);
	s.sync;
	Pdef(\tempo, (~tempo ? 2));
	~basepatt = Pbind(
		\out, ~output, 
		\instrument, \ps_flange_chorister_del_bp_compand,
//		\instrument, \ps_flange_grain_del_bp_compand,
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
		\wideness, Pexprand(0.25, 2, inf),
		\decaytime, Pexprand(0.1, 0.2, inf)
	);
	~patt = Pbindf(~basepatt,
		\dur, 0.1, // Pdef(\tempo).reciprocal/4.max(0.05),
		\release, Pkey(\dur)* 2.pow(Prand((1..5), inf)),
		\ratiod, 2.pow(Prand((-2..1), inf))*Prand([4/3, 5/4, 1, 1], inf),
		\ratiof, 2.pow(Prand((-2..1), inf))*Prand([4/3, 5/4, 1, 1], inf),
		\ratiodb, 2.pow(Prand((-2..2), inf))*Prand([3/4, 4/3, 1], inf),
		\bigdelay, ~beat.asMap
	);
	~ppatt=~patt.play;
	~tempoupdate=Routine({
		loop {~tempobus.get({|tempo|
			(tempo.notNil && (tempo>0)).if {
				tempo = tempo.max(0.1).min(10);
				TempoClock.default.tempo = tempo;
				["tempo is now", tempo].postln;
				~tempo=tempo;
				Pdef(\tempo, tempo);
			};
		});
		1.yield;}
	}).play(TempoClock.new);
});
)

~tempobus.get;
~beat.get;
~mastersafetyfx.set(\pregain, 3);
~spdifinput = Bus.newFrom(s.inputBus,8,2);
{Out.ar(0, In.ar(Bus.newFrom(s.inputBus,8,2),2));}.play;
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
