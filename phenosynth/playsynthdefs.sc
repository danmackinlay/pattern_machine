PSBasicPlaySynths {
	*initClass{
		StartUp.add({
			SynthDef.writeOnce(
				\ps_reson_saw,
				{ |out=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5|
					var env;
					var time = 1;
					env = EnvGen.kr(
						Env.asr(time/2, 1, time/2, 'linear'),
						gate: gate//,
						//doneAction: 2
					);
					Out.ar(out, Resonz.ar(
						Saw.ar(pitch),
							ffreq,	 //cutoff
							rq			 //inverse bandwidth
						)*env
					);
				}
			);
		});
	}
}
