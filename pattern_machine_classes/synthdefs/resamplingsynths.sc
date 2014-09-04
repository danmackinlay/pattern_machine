/*
delay/echo grains
*/
PSResamplingSynthDefs {
	classvar log001;
	*initClass{
		log001 = 0.001.log;
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	//SC's default of specifying delays as decay times is cute, but not always what you want.
	*decayTimeFromMag{|mag, delaytime|
		^(log001*delaytime/(mag.abs.log) * (mag.sign)).clip2(1000000)
	}
	*loadSynthDefs {
		SynthDef.new(\ps_echette__1x2,
			{|in=0, out=0, deltime=0.1, ringtime=1, amp=1, pan=0|
				var env, sig;
				sig = In.ar(in, 1) * EnvGen.kr(
					Env.sine(dur:deltime),
					levelScale: (ringtime/deltime).sqrt //normalises power *rate*
				);
				env = EnvGen.kr(
					Env.linen(
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
				Out.ar(out, sig);
				}, [\ir, \ir, \ir, \ir, \ir, \ir]
		).add;
		SynthDef.new(\ps_echette_colored__1x2,
			{|in=0, out=0, deltime=0.1, ringtime=1, amp=1, freq=440, color=0.5, pan=0|
				var env, sig, combdelaytime, combdecaytime, coloramp, invpowerest;
				combdelaytime = freq.reciprocal;
				combdecaytime = this.decayTimeFromMag(color, combdelaytime);
				coloramp = color.squared;
				invpowerest = (coloramp-1)/coloramp;
				sig = In.ar(in, 1) * EnvGen.kr(
					Env.sine(dur:deltime),
					levelScale: (ringtime/deltime).sqrt //normalises power *rate*
				);
				env = EnvGen.kr(
					Env.linen(
						sustainTime:deltime,
						releaseTime:ringtime
					), gate:1, doneAction:2
				);
				sig = AllpassN.ar(sig,
					delaytime: deltime,
					decaytime: ringtime,
					maxdelaytime: 0.5);
				sig = CombL.ar(sig,
					maxdelaytime: 0.2,
					delaytime: combdelaytime,
					decaytime: combdecaytime,
					mul: invpowerest*env,
				);
				sig = Pan2.ar(sig, pos:pan);
				Out.ar(out, sig);
				}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir]
		).add;
		
	}
}