PSBasicPlaySynths {
	classvar <synthArgMaps;

	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	/*
	An attempt to make laggedness in synths, though different arg types and
	automagic casting messes with this.
	
	possibly synthArgMaps could make this be sane.
	*makeLagged { |name, func, synthArgMap|
		// create an altered, lagged version 
		var laggedName = (name ++ \_lagged).asSymbol;
		SynthDef.new(laggedName, {
			|outbus=0, gate=1, t_reset=0, lagtime=0.1, ... synthArgs|
			synthArgs = VarLag(synthArgs, lagTime: lagtime);
			SynthDef.wrap(func, prependArgs: synthArgs);
		}).add;
	}
	*/
	*loadSynthDefs{
		synthArgMaps = ();
		// Really simple SynthDef to play a buffer when triggered
		SynthDef.new(\ps_just_playbuf, {|bufnum, outbus=0, t_trig=0|
			Out.ar(outbus, /* SinOsc.ar(440,0,0.1) + */ PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), t_trig));
		});
		synthArgMaps[\ps_just_playbuf] = ();
		SynthDef.new(
			\ps_dc,
			{ |outbus=0, gate=1, amp=1.0|
				Out.ar(outbus, DC.ar(amp));
			}
		).add;
		synthArgMaps[\ps_dc] = (\amp: \unipolar.asSpec);
		SynthDef.new(
			\ps_sine,
			{ |outbus=0, gate=1, t_reset=0, pitch=800, amp=1.0|
				var env, time = 1;
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, SinOsc.ar(pitch, mul: env*amp));
			}
		).add;
		SynthDef.new(
			\ps_reson_saw,
			{ |outbus=0, gate=1, t_reset=0, pitch=800, ffreq=500, rq=0.5, amp=1.0|
				var env;
				var time = 1;
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Resonz.ar(
					Saw.ar(pitch, env),
					ffreq,	 //cutoff
					rq			 //inverse bandwidth
				) * env * amp);
			}
		).add;
		synthArgMaps[\ps_reson_saw] = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec,
			\amp: \unipolar.asSpec
		);
		SynthDef.new(
			\ps_reson_saw_lagged,
			{ |outbus=0, gate=1, t_reset=0, lagtime=0.1, pitch=800, ffreq=500, rq=0.5, amp=1.0|
				var env;
				var time = 1;
				pitch = Lag.kr(pitch, lagtime);
				ffreq = Lag.kr(ffreq, lagtime);
				rq = Lag.kr(rq, lagtime);
				amp = Lag.kr(amp, lagtime);
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Resonz.ar(
					Saw.ar(pitch, env),
					ffreq,//cutoff
					rq		//inverse bandwidth
				) * env * amp);
			}
		).add;
		synthArgMaps[\ps_reson_saw_lagged] = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec,
			\amp: \unipolar.asSpec
		);

		SynthDef.new(
			\ps_reson_saw_2pan,
			{ |outbus=0, gate=1, t_reset=0, pitch=800, ffreq=500, rq=0.5, amp=1.0, pan=0|
				var env;
				var time = 1;
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Pan2.ar(
					Resonz.ar(
						Saw.ar(pitch, env),
						ffreq,	//cutoff
						rq		//inverse bandwidth
					)
				) * env * amp);
			}
		).add;
		SynthDef.new(
			\ps_sample_grain,
			{ |outbus=0, gate=1, t_reset=0,
					buffer, pitch=1, ffreq=500,
					rq=0.5, amp=1.0, pointer=0.5,
					windowSize=0.1, windowRandRatio=0.5|
				var env;
				var time = 1;
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Resonz.ar(
					Warp1.ar(
						bufnum: buffer,
						freqScale: pitch,
						mul: env,
						pointer: pointer,
						windowSize: windowSize,
						windowRandRatio: windowRandRatio),
					ffreq,	 //cutoff
					rq		 //inverse bandwidth
				) * env * amp);
			}
		).add;
		synthArgMaps[\ps_sample_grain] = (
			\pitch: ControlSpec.new(minval: 4.reciprocal, maxval: 4, warp: 'exp', default:1),
			\ffreq: \midfreq.asSpec,
			\pointer: \unipolar.asSpec,
			\windowRandRatio: \unipolar.asSpec,
			\windowSize: ControlSpec.new(minval: 4.reciprocal, maxval: 1, warp: 'exp'),
			\rq: \rq.asSpec,
			\amp: \unipolar.asSpec
		);
		SynthDef.new(
			\ps_sample_grain_lagged,
			{ |outbus=0, gate=1, t_reset=0,
					buffer, pitch=1, ffreq=500,
					rq=0.5, amp=1.0, pointer=0.5,
					windowSize=0.1, windowRandRatio=0.5, lagtime=0.1|
				var env;
				var time = 1;
				//lag these parameters, but the others are sampled anyway
				pitch = Lag.kr(pitch, lagtime);
				ffreq = Lag.kr(ffreq, lagtime);
				rq = Lag.kr(rq, lagtime);
				amp = Lag.kr(amp, lagtime);
				
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Resonz.ar(
					Warp1.ar(
						bufnum: buffer,
						freqScale: pitch,
						mul: env,
						pointer: pointer,
						windowSize: windowSize,
						windowRandRatio: windowRandRatio,
						overlaps: 2,
					),
					ffreq,	 //cutoff
					rq		 //inverse bandwidth
				) * env * amp);
			}
		).add;
		synthArgMaps[\ps_sample_grain_lagged] = (
			\pitch: ControlSpec.new(minval: 4.reciprocal, maxval: 4, warp: 'exp', default:1),
			\ffreq: \midfreq.asSpec,
			\pointer: \unipolar.asSpec,
			\windowRandRatio: \unipolar.asSpec,
			\windowSize: ControlSpec.new(minval: 4.reciprocal, maxval: 1, warp: 'exp'),
			\rq: \rq.asSpec,
			\amp: \unipolar.asSpec
		);
		SynthDef.new(
			\ps_sample_grain_lfo_lagged,
			{ |outbus=0, gate=1, t_reset=0,
					buffer, pitch=1, ffreq=500,
					rq=0.5, amp=1.0, pointer=0.5,
					windowSize=0.1, windowRandRatio=0.5,
					lforate = 0.1,
					lfoamt=0.0,
					lagtime = 0.1|
				var env, lfo;
				var time = 1;
				//lag these parameters, but the others are sampled anyway
				pitch = Lag.kr(pitch, lagtime);
				ffreq = Lag.kr(ffreq, lagtime);
				rq = Lag.kr(rq, lagtime);
				amp = Lag.kr(amp, lagtime);
				lforate = Lag.kr(lforate, lagtime);
				lfoamt = Lag.kr(lfoamt, lagtime);
				lfo = SinOsc.kr(freq:lforate);
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(outbus, Resonz.ar(
					Warp1.ar(
						bufnum: buffer,
						freqScale: pitch,
						mul: env,
						pointer: pointer,
						windowSize: windowSize,
						windowRandRatio: windowRandRatio,
						overlaps: 2,
					),
					ffreq,	 //cutoff
					rq		 //inverse bandwidth
				) * env * amp * (1+(lfo*lfoamt)));
			}
		).add;
		synthArgMaps[\ps_sample_grain_lfo_lagged] = (
			\pitch: ControlSpec.new(minval: 4.reciprocal, maxval: 4, warp: 'exp', default:1),
			\ffreq: \midfreq.asSpec,
			\pointer: \unipolar.asSpec,
			\windowRandRatio: \unipolar.asSpec,
			\windowSize: ControlSpec.new(minval: 4.reciprocal, maxval: 1, warp: 'exp'),
			\rq: \rq.asSpec,
			\amp: \unipolar.asSpec,
			\lforate: ControlSpec.new(minval: 16.reciprocal, maxval: 16, warp: 'exp'),
			\lfoamt: \unipolar.asSpec,
		);
	}
}
