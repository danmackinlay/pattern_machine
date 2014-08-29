s=Dan.serverboot(prox:\local, device:\rme);
s=Dan.serverboot(prox:\local, device:\internal);
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Routing-audio-synths-using-ProxySpace-td6416833.html"
// "http://comments.gmane.org/gmane.comp.audio.supercollider.user/65142"
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/JITLib-basics-td6990590.html"
(
var state = ();
~state=state;
fork {state.make({
	// DIY diffusers
	var diffuserfactory ={|ingraph, mixgraph, outchan=1|
		var basicdiffuser;
		basicdiffuser = { |out, in,
			lforate=0.21,
			delay=0.1,
			delayvar=0.0,
			gain=0.5,
			gainvar=0.0,
			gate=1,
			dry=0.0|
			var baseSig, sigs, basePhasor, delayLo, delayHi, gainLo, gainHi, masterenv, overlap=4;
			delayLo = (delay-delayvar).max(0.001);
			delayHi = (delay+delayvar).min(0.5);
			gainLo = (gain-gainvar).max(0);
			gainHi = (gain+gainvar).min(1);

			basePhasor = LFSaw.kr(lforate) * overlap;
			baseSig = ingraph.value(in);
			//baseSig = in;
			masterenv = EnvGen.kr(Env.cutoff, doneAction:2, gate:gate);
			//basePhasor.poll(1,\baseph);
			sigs = baseSig.collect({|chan, inidx|
				var grainsigs;
				grainsigs = overlap.collect( {|phaseidx|
					var phasor, env, active;
					phasor = (basePhasor + phaseidx).wrap2(overlap/2);
					//phasor.poll(1,\ph++phaseidx, phaseidx);
					//chan.poll(1,\phi++inidx, phaseidx);
					active = phasor.abs <= 1;
					env = CentredApprox.sqrtHalfCos(phasor.clip2(1));
					// env.poll(1,\env, env);
					// TRand.kr(delayLo, delayHi, trig: active).poll(1, \del, phase);
					// (TRand.kr(gainLo, gainHi, trig: active)*env).poll(1, \gain, phase);
					DoubleNestedAllpassN.ar(chan,
						maxdelay1: 0.5,
						delay1: TRand.kr(delayLo, delayHi, trig: active),
						gain1: TRand.kr(gainLo, gainHi, trig: active)*env,
						maxdelay2: 0.5,
						delay2: TRand.kr(delayLo, delayHi, trig: active),
						gain2: TRand.kr(gainLo, gainHi, trig: active)*env,
						maxdelay3: 0.5,
						delay3: TRand.kr(delayLo, delayHi, trig: active),
						gain3: TRand.kr(gainLo, gainHi, trig: active)*env,
						mul: env*masterenv, add: 0);
					//SynthDef.wrap(mixgraph, prependArgs:[grainsig, inidx])
				});
				mixgraph.value(grainsigs, inidx);
			}).sum;
				// Amplitude.kr(baseSig).poll(1,\inamp);
			// Amplitude.kr(sigs).poll(1,\outamp);
			// out.poll(1,\in);
			Out.ar(out, sigs + (dry*baseSig).sum);
			//Out.ar(out, sigs);
			//Out.ar(out, baseSig);
		};
	};
	~c1x1=SynthDef.new(\ps_mutatingreverb_4__1x1,
		diffuserfactory.value(
			{|in|[In.ar(in,1)]},
			{|chan, i| chan.sum},
			outchan:1,
		)
	).add;
	~c1x2=SynthDef.new(\ps_mutatingreverb_4__1x2,
		diffuserfactory.value(
			{|in|[In.ar(in,1)]},
			{|chan, i|
				//chan.poll(5,\flarg1, i);
				Splay.ar(chan)},
			outchan:2,
		)
	).add;
	~c2x2=SynthDef.new(\ps_mutatingreverb_4__2x2,
		diffuserfactory.value(
			{|in|In.ar(in,2)},
			{|chan, i|
				//chan.poll(5, \flarg2, i);
				Splay.ar(chan, spread: 1-(2*i))},
			outchan:2,
		)
	).add;
	~testsamplepath = PS.scsamplepath +/+ "NS-wind-chimes-002-denoise-edit.wav";
	~testbuf=Buffer.read(s, ~testsamplepath);
	~outbus = Bus.new(\audio, 0, 2, s);
	s.sync;
	~testsound = Synth.head(
		s,
		\playbuf__1, [
			\outbus, ~outbus.subBus(0,1),
			\bufnum, ~testbuf
		]
	);
	~reverb = Synth.tail(
		s,
		\ps_mutatingreverb_4__1x2, [
			\in, ~outbus.subBus(0,1),
			\out, ~outbus,
			\delay, 0.3,
			\delayvar, 1,
			\gain, 1,
			\dry, 0,
		]
	);
})};
)
~state.c1x1.dumpUGens;
~state.c1x2.dumpUGens;
~state.c2x2.dumpUGens;
Quarks.gui
SynthDef(\test, {|in,out|Out.ar(out, In.ar(in,2))}).dumpUGens;