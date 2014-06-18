//This one is trying to be a breakbeat guy, but I think I'll have to come back to him when I have time

(
SynthDef(\playbar, {arg buffer = 0, envbuf = -1;
Ê Ê var out, pointer, filelength, pitch, env, dir;
Ê Ê // pointer - move from beginning to end of soundfile over 15 seconds
Ê Ê pointer = Line.kr(0, 1, 15);
Ê Ê // control pitch with MouseX
Ê Ê pitch = MouseX.kr(0.5, 2);
Ê Ê env = EnvGen.kr(Env([0.001, 1, 1, 0.001], [0.1, 14, 0.9], 'exp'), doneAction: 2);
Ê Ê out = Warp1.ar(1, buffer, pointer, pitch, 0.1, envbuf, 8, 0.1, 2);
Ê Ê Out.ar(0, out * env);
}).add;

Warp1.ar (numChannels: 1, bufnum: 0, pointer: 0, freqScale: 1, windowSize: 0.2, envbufnum: -1, overlaps: 8, windowRandRatio: 0, interp: 1, mul: 1, add: 0)
)

(
var ps;
~logger = PostLogger.new();
ps = PSProductionSystem(~logger, trace:true);
~clock=TempoClock.new(108/60);
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, POp(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, POp(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, POp(\stretch, Affine1(3)));
ps.putOp(\h3on2, POp(\harmonic, Affine1(3/2)));
ps.putOp(\h4on3, POp(\harmonic, Affine1(4/3)));
ps.putOp(\h2on3, POp(\harmonic, Affine1(2/3)));
ps.putOp(\h3on4, POp(\harmonic, Affine1(3/4)));
ps.putOp(\rotateRight, POp(\pan, (_+0.25).wrap(-1,1)));
ps.putOp(\rotateLeft, POp(\pan, (_-0.25).wrap(-1,1)));

ps.putAtom(\note, Pobind(\note, 0, \harmonic, 1, \legato, 2, \dur, 1, \pan, 0));
ps.putAtom(\onebeatrest, PoRest(1));

ps.putRule(\ornament,
	PSChoice(
		1, [\note],
		2, [\timetransform, \freqtransform, \rotate, PSParen(\note, \ornament)]
	)
);
ps.putRule(\timetransform,
	PSChoice(
		2, [\doubleSpeed],
		1, [\halfSpeed],
		2, [\tripleSpeed],
		1, [\thirdSpeed],
	)
);
ps.putRule(\freqtransform,
	PSStarN(1, PSChoice(
		4, [\h3on2],
		2, [\h4on3],
		4, [\h2on3],
		2, [\h3on4],
	))
);
ps.putRule(\rotate,
	PSChoice(
		1, [\rotateRight],
		1, [\rotateLeft],
	)
);
ps.putRule(\bar,
	PSBranch(
		[\ornament],
	),
	\onebeatrest, \onebeatrest);
ps.putRule(\root, PSStar(\bar));
~ps=ps;
//~patt=Ptrace(ps.root);
~patt=ps.root;
~logger.minPriority = 2;
~patt.play(~clock);
)
~logger.minPriority=0;
