SynthDef.new(\echette_live__1_2,
	{|inbus=0, outbus=0, deltime=0.1, ringtime=1, pan=0|
		var env, sig;
		sig = In.ar(inbus, 1) * EnvGen.kr(Env.sine(dur:deltime));
		env = EnvGen.kr(
			Env.linen(
				attackTime:0,
				sustainTime:deltime,
				releaseTime:ringtime
			), gate:1, doneAction:2
		);
		sig = AllpassN.ar(sig,
			delaytime: deltime,
			decaytime: ringtime,
			maxdelaytime: 0.5,
			mul: env);
		sig = Pan2.ar(sig, pos:pan);
		Out.ar(outbus, sig);
	}
).add;
