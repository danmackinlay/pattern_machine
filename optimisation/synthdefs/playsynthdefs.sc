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
			|out=0, gate=0, t_reset=0, lagtime=0.1, ... synthArgs|
			synthArgs = VarLag(synthArgs, lagTime: lagtime);
			SynthDef.wrap(func, prependArgs: synthArgs);
		}).add;
	}
	*/
	*loadSynthDefs{
			synthArgMaps = ();
			// Really simple SynthDef to play a buffer when triggered
			SynthDef.new(\ps_just_playbuf, {|bufnum, out=0, t_trig=0|
				Out.ar(out, /* SinOsc.ar(440,0,0.1) + */ PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), t_trig));
			});
			synthArgMaps[\ps_just_playbuf] = ();
			SynthDef.new(
				\ps_dc,
				{ |out=0, gate=0, gain=1.0|
					Out.ar(out, DC.ar(gain));
				}
			).add;
			synthArgMaps[\ps_dc] = (\gain: \unipolar.asSpec);
			SynthDef.new(
				\ps_sine,
				{ |out=0, gate=0, t_reset=0, pitch=800, gain=1.0|
					var env, time = 1;
					env = EnvGen.kr(
						Env.asr(time/2, 1, time/2, 'linear'),
						gate: gate,
						doneAction: 0
					);
					Out.ar(out, SinOsc.ar(pitch, mul: env*gain));
				}
			).add;
			SynthDef.new(
				\ps_reson_saw,
				{ |out=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5, gain=1.0|
					var env;
					var time = 1;
					env = EnvGen.kr(
						Env.asr(time/2, 1, time/2, 'linear'),
						gate: gate,
						doneAction: 0
					);
					Out.ar(out, Resonz.ar(
						Saw.ar(pitch, env),
						ffreq,	 //cutoff
						rq			 //inverse bandwidth
					) * env * gain);
				}
			).add;
			synthArgMaps[\ps_reson_saw] = (
				\pitch: \midfreq.asSpec,
				\ffreq: \midfreq.asSpec,
				\rq: \rq.asSpec,
				\gain: \unipolar.asSpec
			);

			SynthDef.new(
				\ps_reson_saw_2pan,
				{ |out=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5, gain=1.0, pan=0|
					var env;
					var time = 1;
					env = EnvGen.kr(
						Env.asr(time/2, 1, time/2, 'linear'),
						gate: gate,
						doneAction: 0
					);
					Out.ar(out, Pan2.ar(
						Resonz.ar(
							Saw.ar(pitch, env),
							ffreq,	//cutoff
							rq		//inverse bandwidth
						)
					) * env * gain);
				}
			).add;
			SynthDef.new(
				\ps_sample_grain,
				{ |out=0, gate=0, t_reset=0,
						buffer, pitch=1, ffreq=500,
						rq=0.5, gain=1.0, pointer=0.5,
						windowSize=0.1, windowRandRatio=0.5|
					var env;
					var time = 1;
					env = EnvGen.kr(
						Env.asr(time/2, 1, time/2, 'linear'),
						gate: gate,
						doneAction: 0
					);
					Out.ar(out, Resonz.ar(
						Warp1.ar(
							bufnum: buffer,
							freqScale: pitch,
							mul: env,
							pointer: pointer,
							windowSize: windowSize,
							windowRandRatio: windowRandRatio),
						ffreq,	 //cutoff
						rq		 //inverse bandwidth
					) * env * gain);
				}
			).add;
			synthArgMaps[\ps_sample_grain] = (
				\pitch: ControlSpec.new(minval: 4.reciprocal, maxval: 4, warp: 'exp', default:1),
				\ffreq: \midfreq.asSpec,
				\pointer: \unipolar.asSpec,
				\windowRandRatio: \unipolar.asSpec,
				\windowSize: ControlSpec.new(minval: 4.reciprocal, maxval: 1, warp: 'exp'),
				\rq: \rq.asSpec,
				\gain: \unipolar.asSpec
			);
	}
}
