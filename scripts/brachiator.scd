(
var patt, ps = PSProductionSystem(PostLogger.new, trace:true);
~clock=TempoClock.new(108/60);
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, POp(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, POp(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, POp(\stretch, Affine1(3)));
//ps.putOp(\h3on2, POp(\harmonic, Affine1(3/2)));
//ps.putOp(\h4on3, POp(\harmonic, Affine1(4/3)));
ps.putOp(\h3on2, POp(\note, Affine1(1,7)));
ps.putOp(\h4on3, POp(\note, Affine1(1,5)));

ps.putAtom(\note, Pobind(\note, 0, \harmonic, 1, \legato, 2, \dur, 1));
ps.putAtom(\onebarrest, PoRest(4));

ps.putRule(\ornament,
	PSWlist(
		1, [\note],
		2, [\note, \transformset, PSParen(\ornament)]
	)
);
ps.putRule(\transformset,
	PSWlist(
		2, [\transform],
		1, [\transformset, \transform]
	)
);
ps.putRule(\transform,
	PSWlist(
		2, [\doubleSpeed],
		1, [\halfSpeed],
		2, [\tripleSpeed],
		1, [\thirdSpeed],
		2, [\h3on2],
		1, [\h4on3],
	)
);
ps.putRule(\bar,
	PSBranch(
		[\ornament],
	),
	\onebarrest);
ps.putRule(\root, PSStar(\bar));
~ps=ps;
patt = ps.root;
~steps = TestPS.expressPattern(patt);
~patt=patt;
~patt.play(~clock);
)
~ps.at(\transform);