m=MandelHub.start(\dan, 120/60);
m.leaderName;
m.clear;
MandelHub.clear;
m.takeLead;
m.shout("aaaaaa");
m.gui;
m.changeTempo(120/60);
x = m.space;
m.chat("who am i again?");
m.chat("how about now?");
Pbind(\degree, Pfunc({x[\degree]})).play(m.clock);
~state[\degree]=4;
Pbind(\degree, 4, \octave, 4).play(TempoClock.default);
Pbind(\degree, Pfunc({~state[\degree]}), \octave, 4).play(TempoClock.default);
p=Instr([\cymbals, \tibetanCymbals2]).play(m.clock);
p.stop

~steps1 = Array.series(3001, 0, 1)/3000;
~steps33 = Array.series(3001, -1500, 1)/500;
~steps.plot;
PSPsi(PSInvPsi(~steps1)).plot;
PSInvPsi(~steps1).plot;
PSPsi(~steps33).plot;
~rng = LinCongRNG.new;
~steps1.collect({|i| PSGaussCorrelate.unifUnifToGauss(0.99, i, ~rng.next)}).plot;
{PSInvPsi(LFSaw.ar(mul:0.5, add:0.5))}.plot;

SynthDef(\bell,
	{ arg specArray, trig, decay=0.04, noise=0.03, freqScale=1.0, timeScale=1.0;
		var z;
		z=
		//geyyynk
		[ `(#[ [ 2988.36, 4641.85, 1200.73, 2105.13, 2451.75, 4592.98, 4800.1, 3859.57, 4035.55, 4077.45,
		  3687.67, 1646.68, 1739.28, 1321.81, 2690.67, 4233.29, 1505.58, 1718.2, 751.362, 4965.17,
		  3522.6 ], nil, [ 0.149236, 0.237282, 0.0344865, 0.348832, 0.0220867, 0.0238802, 0.0295692, 0.0481518, 0.154031, 0.125693,
		  0.0471917, 0.0203231, 0.0393852, 0.0989048, 0.0537919, 0.119769, 0.0258739, 0.145177, 0.0808096, 0.0388504,
		  0.252425 ] ]), `(#[ [ 2158.3, 2258.49, 3983.57, 770.949, 4877.25, 3541.82, 1669.77, 2424.43, 3923.18, 4890.52,
		  4961.3, 5334.93, 4025.32, 4633.61, 3788.61, 4628.54, 3662.69, 5221.49, 4300.53, 1546.1,
		  4156.23 ], nil, [ 0.253346, 0.0352605, 0.119383, 0.0633781, 0.0635492, 0.0124307, 0.0354971, 0.13337, 0.398734, 0.0236294,
		  0.1393, 0.0103872, 0.0715449, 0.069538, 0.262093, 0.0732683, 0.0116285, 0.105353, 0.036287, 0.216802,
		  0.0802132 ] ]) ];

		Klank.ar(z, Decay.ar(Impulsar.ar(trig), decay, WhiteNoise.ar(noise)),freqScale,0.0,timeScale);
}).add;
