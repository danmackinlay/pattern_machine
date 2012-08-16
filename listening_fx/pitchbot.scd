Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);


//Todo:
// extend this to keep a bag of amplitudes to hand as well.

(
SynthDef(\ps_pitch_writer, {
	|inbus, i_bufpointer, i_buffer, baserate=20, certthresh=0.9, ampthresh=0.1, ampscale=3, pitchthresh=100, dopoll=1|
	var trig, gate, pitch, certainty, amp, counter, write, buflen;
	buflen = BufFrames.ir(i_buffer)-1; //last sample gets filled with crap due to rude phase wrapping
	inbus = In.ar(inbus);
	#pitch, certainty = Tartini.kr(inbus);
	amp = Amplitude.kr(inbus);
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
SynthDef(\tempotrack, {|inbus, outbus, tempoout=(-1), beatout=(-1), vol=0.0, beepvol=0.0, lock=0|
	var fft, resample, fftbuffer;
	var trackb,trackh,trackq,tempo;
	var bsound,hsound,qsound, beep;
	fftbuffer = LocalBuf(1024, 1);

	inbus = In.ar(inbus);

	fft = FFT(fftbuffer, inbus);

	#trackb,trackh,trackq,tempo=BeatTrack.kr(fft, lock);

	tempo = Clip.kr(tempo, 0.1, 10);
	beep = SinOsc.ar(1000,0.0,Decay.kr(trackb,0.1));
	Out.kr(tempoout, tempo);
	Out.kr(beatout, tempo.reciprocal);
	Out.ar(outbus, Pan2.ar((vol*inbus)+(beepvol*beep), 0.0));
}).add;
~trackpitch = {|i_bufpointer, i_buffer, maxdel=50|
	 BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			inbus: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo: 0,
			hi: (BufFrames.ir(i_buffer)-1)
		),
		interpolation:1
	).max(1);
};
SynthDef(\ps_flange_chorister_del_bp, {
	|delbuf, phasein, outbus, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1|
	var inbus, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(inbus: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(inbus: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
	attack = attack*(pitch>minf)*(bpitch>minf);
	//Linear envelope, coz it gets squared.
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	inbus = DelTapRd.ar(buffer:delbuf, phase:In.kr(phasein), delTime:bigdelay)*env;
	sig  = Pan2.ar(inbus, Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		inbus: sig,
		freq: bpitch*i_ratiof,
		bwr: wideness
	);
	delay = (pitch*i_ratiod).reciprocal;
	sig = CombN.ar(
		inbus: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: decaytime,
		mul:env);
	sig = sig*env;
	Out.ar(outbus, sig);
}).add;
SynthDef(\ps_flange_chorister_del_bp_compand, {
	|delbuf, phasein, outbus, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1, thresh=0.001, slopeAbove=0.1|
	var inbus, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(inbus: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(inbus: (~trackpitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
	attack = attack*(pitch>minf)*(bpitch>minf);
	//Linear envelope, coz it gets squared.
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	inbus = DelTapRd.ar(buffer:delbuf, phase:In.kr(phasein), delTime:bigdelay)*env;
	sig  = Pan2.ar(inbus, Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		inbus: sig,
		freq: bpitch*i_ratiof,
		bwr: wideness
	);
	delay = (pitch*i_ratiod).reciprocal;
	sig = CombN.ar(
		inbus: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: decaytime,
		mul:env);
	sig = Compander.ar(sig, sig, thresh: thresh, slopeAbove:slopeAbove, mul: (thresh+((1-thresh)*slopeAbove)).reciprocal);
	sig = sig*env;
	Out.ar(outbus, sig);
}).add;
~choosepitch = {|i_bufpointer, i_buffer, maxdel=50|
	 LastValue.kr(BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			inbus: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo: 0,
			hi: (BufFrames.ir(i_buffer)-1)
		),
		interpolation:1
	), inf).max(1);
};
SynthDef(\ps_flange_grain_del_bp, {
	|delbuf, phasein, outbus, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1|
	var inbus, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(inbus: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(inbus: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
	attack = attack*(pitch>minf)*(bpitch>minf);
	//Linear envelope, coz it gets squared.
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	inbus = DelTapRd.ar(buffer:delbuf, phase:In.kr(phasein), delTime:bigdelay)*env;
	sig  = Pan2.ar(inbus, Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		inbus: sig,
		freq: bpitch*i_ratiof,
		bwr: wideness
	);
	delay = (pitch*i_ratiod).reciprocal;
	sig = CombN.ar(
		inbus: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: decaytime,
		mul:env);
	sig = sig*env;
	Out.ar(outbus, sig);
}).add;
SynthDef(\ps_flange_grain_del_bp_compand, {
	|delbuf, phasein, outbus, bigdelay=0.1, attack=0.1, release=0.2, i_bufpointer, i_buffer, maxdel=50, i_ratiod=0.5, i_ratiof=2, i_ratiodb=0.5, wideness=1, decaytime=1, thresh=0.001, slopeAbove=0.1|
	var inbus, pitch, bpitch, delay, sig, env, minf=40, maxf=4000;
	pitch = Clip.kr(inbus: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bpitch = Clip.kr(inbus: (~choosepitch.(i_bufpointer, i_buffer, maxdel)), lo:minf, hi:maxf);
	bigdelay = Clip.kr(LastValue.kr(bigdelay, inf)* i_ratiodb, lo:0.05, hi:1);
	release = (release*(pitch>minf)*(bpitch>minf)).max(0.05);
	attack = attack*(pitch>minf)*(bpitch>minf);
	//Linear envelope, coz it gets squared.
	env = EnvGen.kr(Env.perc(attackTime:attack, releaseTime:release, level:1.0, curve:\lin), gate:1, doneAction:2);
	inbus = DelTapRd.ar(buffer:delbuf, phase:In.kr(phasein), delTime:bigdelay)*env;
	sig  = Pan2.ar(inbus, Rand(lo:-1, hi:1));
	sig = Resonz.ar(
		inbus: sig,
		freq: bpitch*i_ratiof,
		bwr: wideness
	);
	delay = (pitch*i_ratiod).reciprocal;
	sig = CombN.ar(
		inbus: sig,
		maxdelaytime: 0.1,
		delaytime: delay,
		decaytime: decaytime,
		mul:env);
	sig = Compander.ar(sig, sig, thresh: thresh, slopeAbove:slopeAbove, mul: (thresh+((1-thresh)*slopeAbove)).reciprocal);

	sig = sig*env;
	Out.ar(outbus, sig);
}).add;
//I get very occasional exploding peaks of doom inbus here, so I aggressively hunt and destroy
SynthDef(\antifbdelaylimit, {
	|outbus, pregain=1.0, delay=0.5, lookahead=0.05, mindelay=0.2|
	var inbus = In.ar(outbus, 2);
	inbus = Select.ar(CheckBadValues.ar(inbus, 0, 0), [inbus, DC.ar(0), DC.ar(0), DC.ar(0)]);
	inbus = LeakDC.ar(inbus, mul:pregain);
	//Limiters are OK, but they don't stop the real nasty explosions
	inbus = inbus * (1-Trig1.kr(((inbus.abs)>2), 0.1));
	inbus = Limiter.ar(inbus, level: 0.5, dur:lookahead);
	inbus = DelayN.ar (inbus, maxdelaytime: 5, delaytime: Clip.kr((delay-lookahead), mindelay, 5));
	ReplaceOut.ar(outbus, inbus);
}).add;
SynthDef(\ducker, {
	|outbus, sidechain, threshold=0.4, slopeAbove=0.1, clampTime=0.01, relaxTime=0.3|
	var inbus = In.ar(outbus, 2);
	sidechain = Mix.new(In.ar(sidechain, 2));
	inbus = Compander.ar(inbus, sidechain, slopeAbove: slopeAbove, clampTime:clampTime, relaxTime:relaxTime);
	ReplaceOut.ar(outbus, inbus);
}).add;
SynthDef(\reverb, {
	|outbus,mix=1, room=0.9, damp=0.4|
	var inbus = In.ar(outbus, 2);
	inbus = FreeVerb2.ar(inbus[0], inbus[1], mix:mix, room:room, damp:damp);	ReplaceOut.ar(outbus, inbus);
}).add;
SynthDef(\tee, {
	|outbus, out2|
	var inbus = In.ar(outbus, 2);
	//ReplaceOut.ar(outbus, inbus);
	Out.ar(out2, inbus);
}).add;
SynthDef(\injectfb, {
	|inbus, outbus, amp=0.5|
	inbus = InFeedback.ar(inbus, 2);
	Out.ar(outbus, inbus*amp);
}).add;
SynthDef(\delwrite, {|inbus, buffer, phaseout|
	var tapPhase;
	tapPhase = DelTapWr.ar(buffer, Mix.new(In.ar(inbus,2)));
	Out.kr(phaseout, tapPhase);
}).add;
)
/*
~chooseoffsetpitch = {|i_bufpointer, i_buffer, maxdel=50|
	 BufRd.kr(
		numChannels:1,
		bufnum: i_buffer,
		phase: Wrap.kr(
			inbus: (In.kr(i_bufpointer)-(Rand(lo:0, hi: maxdel))),
			lo:0,
			hi: BufFrames.ir(i_buffer)-1
		),
		interpolation:1
	).max(1);
};*/
//chorister version
(
s.waitForBoot( fork {
	//~log = FileLogger.global;
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
	~player = ~playFile.(outbus:~analyseinput, target: ~inputgroup, loop:1, );
	~pitchwriter = Synth.new(\ps_pitch_writer, [\inbus, ~analyseinput, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \ampthresh, 0.01, \baserate, 40, \dopoll, 0], target: ~analysisgroup );
	~tempotracker = Synth.new(\tempotrack, [\inbus, ~analyseinput, \tempoout, ~tempobus, \beatout, ~beat, \outbus, ~output, \vol, 0.0], target: ~analysisgroup );
	~mastersafetyfx = Synth.new(\antifbdelaylimit, [\outbus, ~output, \delay, ~beat.asMap, \lookahead, 0.1, \pregain, 3], target: ~masterfxgroup );
	~ducker = Synth.new(\ducker,  [\outbus, ~output, \sidechain, ~fxinput, \threshold, 0.1, \slopeAbove, 0], target: ~outputmasterfxgroup);
	~reverb = Synth.new(\reverb,  [\outbus, ~output, \mix, 0.5, \room, 0.1, \damp, 0.3], target: ~outputmasterfxgroup, addAction: \addToTail);
	~delayin = Synth.new(\delwrite, [\inbus, ~fxinput, \buffer, ~delbuffer, \phaseout, ~delbufpos], target: ~fxgroup, addAction:\addToHead );
	//~tee = Synth.new(\tee, [\outbus, ~output, \out2, ~fboutput], target: ~fbgroup );
	//~fb = Synth.new(\injectfb, [\inbus, ~output, \outbus, ~fxinput], target: ~fxgroup, addAction:\addToHead );
	//~fb.set(\amp, 0.5);
	//~pitchsprayer = Synth.new(\ps_pitch_spray, [\i_bufpointer, ~pitchbufpos, \outbus, ~pitches, \i_buffer, ~pitchbuffer], target:~pitchwriter, addAction: \addAfter);
	//~pitchsprayer.set(\maxdel, 10);
	s.sync;
	Pdef(\tempo, (~tempo ? 2));
	~basepatt = Pbind(
		\outbus, ~output,
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
Synth.new(\ps_flange_grain_del_bp, [\delbuf, ~delbuffer, \phasein, ~delbufpos, \outbus, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \release, 25, \maxdel, 10], target:~fxgroup).trace;
10.do({Synth.new(\ps_flange_grain_del_bp, [\delbuf, ~delbuffer, \phasein, ~delbufpos, \outbus, ~output, \i_bufpointer, ~pitchbufpos, \i_buffer, ~pitchbuffer, \release, 25, \maxdel, 10, \bigdelay, {0.1.rrand(1);}], target:~fxgroup);});
~pitchwriter.set(\dopoll, 0);
~pitchwriter.trace;
~pitchwriter.trace;
~delbufpos.get;
~ppatt.stop;
~pitchbuffer.plot;
~pitchbufpos.get(_.postln);
~pitchbufpos;
~tempotracker.set(\vol, 0.6);
