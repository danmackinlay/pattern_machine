PSReverbSynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		//Reverb unit with bonus dry sidemix
		this.loadMutator;
		SynthDef(\ps_freeverbside__2x2, {
			|out=0, wet=1, room=0.15, damp=0.8, amp=1.0, sidebus=0, sidebusAmp=1, index=0|
			var signal;
			signal = In.ar(out, 2);
			signal = FreeVerb2.ar(
				signal[0],
				signal[1],
				mix: wet,
				room: room*(index/100 +1),
				damp: damp,
				mul: amp
			);
			//Freeverb is a little low rent and rings a lot; phase that away
			signal = OnePole.ar(AllpassC.ar(signal,
				maxdelaytime:0.1,
				delaytime: SinOsc.ar(
					index/73+0.02,
					mul:0.005,
					add: 0.021+(index/150)),
				decaytime:0.051),
				coef: 0.5, mul: 1.5);
			signal = signal + (In.ar(sidebus, 2)*sidebusAmp);
			ReplaceOut.ar(out,
				signal
			);
		}).add;
		//Reverb unit with bonus dry sidemix
		SynthDef(\ps_gverbside__2x2, {
			|out=0, wet=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel=1.0, earlyreflevel=0.5, sidebus=0, sidebusAmp=1, index=0|
			var drysig, wetsig;
			drysig = In.ar(out, 2);
			wetsig = drysig.collect({|chan|
				GVerb.ar(
					chan,
					roomsize: roomsize*(index/100 +1),
					damping: damping,
					taillevel: taillevel,
					revtime: revtime*(index/100 +1),
					drylevel: 0,
					maxroomsize:400,
					earlyreflevel:earlyreflevel,
				)[0]; //thow out a channel
			})*amp;
			ReplaceOut.ar(out,
				XFade2.ar(drysig,wetsig,wet.linlin(0,1,-1,1)) + (In.ar(sidebus, 2)*sidebusAmp);
			);
		}).add;
		SynthDef(\ps_gverb__2x2, {
			|out=0, wet=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel=1.0, earlyreflevel=0.5, index=0|
			var drysig, wetsig;
			drysig = In.ar(out, 2);
			wetsig = drysig.collect({|chan|
				GVerb.ar(
					chan,
					roomsize: roomsize*(index/100 +1),
					damping: damping,
					taillevel: taillevel,
					revtime: revtime*(index/100 +1),
					drylevel: 0,
					maxroomsize:400,
					earlyreflevel:earlyreflevel,
					mul: amp,
				)[0]; //thow out a channel
			})*amp;
			ReplaceOut.ar(out,
				XFade2.ar(drysig,wetsig,wet.linlin(0,1,-1,1))
			);
		}).add;
	}
	*loadMutator {
		// DIY diffuser, loads up several versions w/ differing channel setup
		//TODO: recirculation delay
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
						// TExpRand.kr(delayLo, delayHi, trig: active).poll(1, \del, phase);
						// (TExpRand.kr(gainLo, gainHi, trig: active)*env).poll(1, \gain, phase);
						DoubleNestedAllpassN.ar(chan,
							maxdelay1: 0.5,
							delay1: TExpRand.kr(delayLo, delayHi, trig: active),
							gain1: TExpRand.kr(gainLo, gainHi, trig: active)*env,
							maxdelay2: 0.5,
							delay2: TExpRand.kr(delayLo, delayHi, trig: active),
							gain2: TExpRand.kr(gainLo, gainHi, trig: active)*env,
							maxdelay3: 0.5,
							delay3: TExpRand.kr(delayLo, delayHi, trig: active),
							gain3: TExpRand.kr(gainLo, gainHi, trig: active)*env,
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
	}
}