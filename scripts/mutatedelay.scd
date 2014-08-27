s=Dan.serverboot(prox:\local, device:\rme);
s=Dan.serverboot(prox:\local, device:\internal);
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Routing-audio-synths-using-ProxySpace-td6416833.html"
// "http://comments.gmane.org/gmane.comp.audio.supercollider.user/65142"
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/JITLib-basics-td6990590.html"
(
var state = ();
fork {state.make({
	// DIY diffuser
	SynthDef.new(\ps_mutatingreverb_4__1x1, { |out,
		dry=0,
		lforate=0.21,
		delay=0.1,
		gain=0.15,
		gainvar=0.5,
		delvar=0.5,
		gate=1|
		var baseSig, sigs, basePhasor, delLo, delHi, gainLo, gainHi, masterenv, overlap=4;
		delLo = delay*(1-delvar).max(0.001);
		delHi = delay*(1+delvar).min(0.5);
		gainLo = (gain*(1-gainvar).max(0));
		gainHi = (gain*(1+gainvar).min(1));
		delLo.poll(1, \delLo, delLo);
		delHi.poll(1, \delHi, delHi);
		gainLo.poll(1, \gainLo, gainLo);
		gainHi.poll(1, \gainHi, gainHi);

		basePhasor = LFSaw.kr(lforate) * overlap;
		baseSig = In.ar(out);
		//baseSig = in;
		masterenv = EnvGen.kr(Env.cutoff,doneAction:2, gate:gate);
		basePhasor.poll(1,\baseph);
		sigs = Mix.fill(overlap, {|phase|
			var phasor, env, active;
			phasor = (basePhasor + phase).wrap2(overlap/2);
			phasor.poll(1,\ph, phase);
			active = phasor.abs <= 1;
			env = CentredApprox.sqrtHalfCos(phasor.clip2(1));
			env.poll(1,\env, env);
			TRand.kr(delLo, delHi, trig: active).poll(1, \del, phase);
			(TRand.kr(gainLo, gainHi, trig: active)*env).poll(1, \gain, phase);

			DoubleNestedAllpassN.ar(baseSig,
				maxdelay1: 0.5,
				delay1: TRand.kr(delLo, delHi, trig: active),
				gain1: TRand.kr(gainLo, gainHi, trig: active)*env,
				maxdelay2: 0.5,
				delay2: TRand.kr(delLo, delHi, trig: active),
				gain2: TRand.kr(gainLo, gainHi, trig: active)*env,
				maxdelay3: 0.5,
				delay3: TRand.kr(delLo, delHi, trig: active),
				gain3: TRand.kr(gainLo, gainHi, trig: active)*env,
				mul: env*masterenv, add: 0);
		});
		masterenv.poll(1,\env);
		Amplitude.kr(baseSig).poll(1,\inamp);
		Amplitude.kr(sigs).poll(1,\outamp);
		out.poll(1,\in);
		Out.ar(out, dry*baseSig + sigs);
		//Out.ar(out, baseSig);
	}).add;
	~testsamplepath = PS.scsamplepath +/+ "NS-wind-chimes-002-denoise-edit.wav";
	~testbuf=Buffer.read(s, ~testsamplepath);
	~outbus = Bus.new(\audio, 0, 1, s);
	s.sync;
	~testsound = Synth.head(
		s,
		\playbuf__1, [
			\outbus, ~outbus,
			\bufnum, ~testbuf
		]
	);
	~reverb = Synth.tail(
		s,
		\ps_mutatingreverb_4__1x1, [
			\out, ~outbus,
			\delay, 0.3,
			\delayvar, 1,
			\gainvar, 1,
		]
	);
})};
)

