PSBasicPlaySynths {
	*initClass{
		StartUp.add({
			this.classInit;
		});
	}
	*classInit{
		/* I give my *actual* class initialisation the name of classInit, for ease of consistently initialising classes
		*/
		this.loadSynthDefs;
	}
	*loadSynthDefs{
			// First, a utility synth:
		
			// Really simple SynthDef to play a buffer when triggered
			SynthDef.new(\ps_just_playbuf, {|bufnum, out=0, t_trig=0|
				Out.ar(out, /* SinOsc.ar(440,0,0.1) + */ PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), t_trig));
			});
			SynthDef.new(
				\ps_dc,
				{ |out=0, gate=0, gain=1.0|
					Out.ar(out, DC.ar(gain));
				}
			).add;		
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
							rq			//inverse bandwidth
						)
					) * env * gain);
				}
			).add;
	}
}
