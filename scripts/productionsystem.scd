////Examples
(
var patt, ps = PSProductionSystem(PostLogger.new);
ps.putOp(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2)) ;
ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
ps.putOp(\upThird, Pbind(\note, Pkey(\note) + 4)) ;
ps.putOp(\upFifth, Pbind(\note, Pkey(\note) + 5)) ;
ps.putAtom(\riff, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putRule(\phrase, PSWlist(
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\upThird, \phrase],
	1, [\upFifth, \phrase],
	2, [\riff],
));
//We want to have this pattern restart every bar, but the Pfindur pattern does not compose, I think.
//this feels a little unsatisfactory
//Ptrace(Pn(Pfindur(4,~root),10)).play(TempoClock.new(3));
//patt = Ptrace(Pn(Pfindur(4,ps.root),10));
patt = Ptrace(ps.root,10);
~steps = TestPS.expressPattern(patt);
~patt=patt;
)
~patt.play;
~steps = TestPSPattern.expressPattern(~patt);

////Testing:
TestAffine1.run;
TestPOp.run;
TestPS.run;
UnitTest.runTest("TestPS:test_branching");