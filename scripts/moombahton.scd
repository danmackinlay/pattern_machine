(
var patt, ps = PSProductionSystem(PostLogger.new);
ps.putOp(\doubleSpeed, POp(\delta, Affine1(1/2))) ;
ps.putOp(\halfSpeed, POp(\delta, Affine1(2))) ;
ps.putOp(\upThird, POp(\note, Affine1(1,4))) ;
ps.putOp(\upFifth, POp(\note, Affine1(1,7))) ;
ps.putAtom(\riff, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putRule(\phrase, PSWlist(
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\upThird, \phrase],
	1, [\upFifth, \phrase],
	2, [\riff],
));
ps.putRule(\root, \phrase.dup(3));
patt = Ptrace(ps.root,10);
~steps = TestPS.expressPattern(patt);
~patt=patt;
~patt.play;
)
