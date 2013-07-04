s=Server.local;
(
SynthDef.new(\fmnet,{
	|out=0, freq=400, harm1=2, fmod1=0.1, harm2=3, fmod2=0.01|
	var sig = PMOsc.ar(
		carfreq:freq,
		modfreq:PMOsc.ar(
			carfreq: harm1*freq,
			modfreq: harm2*freq,
			mul: fmod2,
		),
		pmindex: fmod1;
	);
	Out.ar(out, sig);
}).add;
)
(
x=Synth.new(\fmnet, [\freq, 200]);
)
x.set(\freq, 400);
x.set(\harm1, 8);
x.set(\fmod1, 1);

/*
notes:
Check out sccode rand-n-step for array of synths
*/
