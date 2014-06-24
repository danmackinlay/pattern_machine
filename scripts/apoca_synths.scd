SynthDef.new(\echette_live__1_2,
	{|in=0,out=0,deltime=0.1,ringtime=1,pan=0|
		var env, sig;
		sig = In.ar(in, 1)* CentredApprox.halfCos(Line.ar(-1,1,deltime)); //or Env.sine?
		env = EnvGen.kr(
			Env.linen(
				attackTime:0, sustainTime:deltime, releaseTime:ringtime
			), gate:1, doneAction:2
		);
		sig = AllpassN.ar(sig, delaytime: deltime,decaytime: ringtime, maxdelaytime:5.0, mul: env);
		sig = Pan2.ar(sig, pos:pan);
		Out.ar(out, sig);
	}
).add;
