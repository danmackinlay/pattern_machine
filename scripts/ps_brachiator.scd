(
var ps;
~logger = PostLogger.new();
ps = PSProductionSystem(~logger, trace:true);
~clock=TempoClock.new(108/60);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, Pop(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, Pop(\stretch, Affine1(3)));
ps.putOp(\h3on2, Pop(\harmonic, Affine1(3/2)));
ps.putOp(\h4on3, Pop(\harmonic, Affine1(4/3)));
ps.putOp(\h2on3, Pop(\harmonic, Affine1(2/3)));
ps.putOp(\h3on4, Pop(\harmonic, Affine1(3/4)));
ps.putOp(\rotateRight, Pop(\pan, (_+0.25).wrap(-1,1)));
ps.putOp(\rotateLeft, Pop(\pan, (_-0.25).wrap(-1,1)));

ps.putAtom(\note, P1bind(\note, 0, \harmonic, 1, \legato, 2, \dur, 1, \pan, 0));
ps.putAtom(\onebeatrest, P1Rest(1));

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
