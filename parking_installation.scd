Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
~openStartup.();
(
SynthDef.new(\ps_oneshot_record, {|in, sndbuffer|
	in = HPF.ar(In.ar(in), freq:80);
	RecordBuf.ar(in, run: 1, trigger: 1, loop:0, doneAction:2);
}).add;
SynthDef.new(\ps_autorecorder, {|in, analout, sndbuffer, pitchbuffer, ampthresh=0.1, certthresh=0.8, lag=0.6, duration=10, pitchid=15, exciteleak=0.9995|
	var recordtrig, amp, certainty, recordable, pitch, currsndbuffer, currpitchbuffer, onset, excitement;
	//TODO implement many buffers with Stepper.kr and Latch.kr
	currsndbuffer = sndbuffer;
	currpitchbuffer = sndbuffer;
	in = HPF.ar(In.ar(in), freq:80);
	# pitch, certainty = Tartini.kr(in);
	certainty = Lag.kr(certainty, lagTime:lag);
	certainty.poll(1, \p);
	//onset = Coyote.kr(in);
	amp = Amplitude.kr(in);
	amp = Lag.kr(amp, lagTime:lag);
	amp.poll(1, \a);
	excitement = Integrator.kr(certainty*amp, coef: exciteleak);
	recordable = (certainty>certthresh)*(amp>ampthresh);
	recordable.poll(1, \r);
	//refractory period - simple style.
	recordable = recordable * LFPulse.kr(freq: duration.reciprocal/2);
	//refractory period - complex version that doesn't work.
	//recordable = recordable * ToggleFF.kr(TDelay.kr(recordable, duration));
	recordable.poll(1, \r2);
	recordtrig = Trig1.kr(recordable, dur: duration);
	recordtrig.poll(1, \rt);
	RecordBuf.ar(in, run: recordtrig, trigger: recordtrig, loop:0);
	SendTrig.kr(in: recordable*LFPulse.kr(freq: 10), value: pitch);
	Out.kr(analout, excitement);
}).add;
SynthDef.new(\ps_twinker, {|out, gate=1, sndbuffer, pitchbuffer, paramrate=3, duty=2, release=1, duration=10.0|
	var paramtrig, graintrig, grainrate, envl, effectiveduration, graindur;
	effectiveduration = duration-1;
	grainrate = paramrate;
	graindur = paramrate.reciprocal * duty;
	graintrig = Impulse.kr(freq: grainrate)-0.1;
	envl = EnvGen.kr(Env.cutoff(release, curve: -4), gate: gate, doneAction:2);
	Out.ar(out,
		envl *
		HPF.ar(
			TGrains.ar(
				numChannels:2,
				trigger:graintrig,
				bufnum:sndbuffer,
				centerPos:graindur/2, //effectiveduration/2,
				rate:1,
				dur: graindur,
				pan: 0,
				amp: 0.5,
				interp: 1
			), freq: 80
		)
	);
}).add;
)
//~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~recBuf = Buffer.alloc(numFrames: s.sampleRate*10.0, numChannels:1);
~controlrate = 5;
~tmpBus = Bus.control(s, 1);
~controlrater = {Out.kr(~tmpBus, ControlRate.ir)}.play;
~tmpBus.get({|r| ~controlrate =r;});
~controlrater.free;
~tmpBus.free;
~controlrate;
~pitchBuf = Buffer.alloc(numFrames: (~controlrate*10.0).ceil, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 2);
~recorder = Synth.new(\ps_autorecorder, [\in, ~in, \sndbuffer,  ~recBuf, \duration, 10]);
~recorder.trace;
~recorder.free;
~recorder = Synth.new(\ps_oneshot_record, [\in, ~in, \sndbuffer,  ~recBuf]);
~recorder.trace;
~recorder.free;
~player = Synth.new(\ps_twinker, [\in, ~in, \out, ~globalOuts, \sndbuffer,  ~recBuf, \duration, 10 ]);
~player.release;

~recBuf.plot;

/*
 * TODO: 
 * * maybe spectrally extract output from input?
 * * or just work out if there is truly a difference by MFCC
 * * record many buffers
 * * provide smart recommendations of volume threshold, poss via GUI.
 * * Dfsm+DiWhite+TGrains for fun granualtions
 * * other fun instruments
 * * go to Wiimote action
 */
 
// demand ugens as inputs
(
{
Ê Ê Ê Ê var trate, dur, z, d;
Ê Ê Ê Ê trate = MouseX.kr(1, 100, 1);
Ê Ê Ê Ê d = { Dwhite(0.1, 0.2, 1) };
Ê Ê Ê Ê z = {
Ê Ê Ê Ê Ê Ê Ê Ê Drand([Dgeom(0.1, 1 + d.value, Diwhite(20, 40)), Dgeom(1, 1 - d.value, Diwhite(20, 40))])
Ê Ê Ê Ê };
Ê Ê Ê Ê TGrains.ar(2,
Ê Ê Ê Ê Ê Ê Ê Ê Impulse.ar(trate),
Ê Ê Ê Ê Ê Ê Ê Ê bufnum: 10,
Ê Ê Ê Ê Ê Ê Ê Ê rate: Dseq([1, 1, z.value, 0.5, 0.5, 0.2, 0.1, 0.1, 0.1, 0.1], inf) * 2 + 1,
Ê Ê Ê Ê Ê Ê Ê Ê centerPos: Dseq(z.dup(8), inf),
Ê Ê Ê Ê Ê Ê Ê Ê dur: Dseq([1, d.value, 1, z.value, 0.5, 0.5, 0.1, z.value] * 2, inf) / trate,
Ê Ê Ê Ê Ê Ê Ê Ê pan: Dseq([1, 1, 1, 0.5, 0.2, 0.1, 0, 0, 0], inf) * 2 - 1,
Ê Ê Ê Ê Ê Ê Ê Ê amp: Dseq([1, 0, z.value, 0, 2, 1.0, 1, 0.1, 0.1], inf)
Ê Ê Ê Ê );
}.scope(zoom: 4);
)
