(
var ps = PSProductionSystem(PostLogger.new);
ps.putOp(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2)) ;
ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
ps.putAtom(\bar, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putRule(\phrase, PSWlist(
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\bar],
));
ps.putRule(\root, \phrase.dup(3));
~ps=ps;
Ptrace(ps.root).play(TempoClock.new(3));
);
~ps.ruleMap;
//Examples
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
~root = ps.putRule(\root, \phrase.dup(3));
//We want to have this pattern restart every bar, but the Pfindur pattern does not compose; it take a pattern as an argument; thus it is imposed from outside;
//this feels a little unsatisfactory
//Ptrace(Pn(Pfindur(4,~root),10)).play(TempoClock.new(3));
//patt = Ptrace(Pn(Pfindur(4,ps.root),10));
patt = Ptrace(ps.root,10);
~notes = TestPS.expressPattern(patt);
)
(
var steps, ps, firstpair, lastpair;
ps = PSProductionSystem.new(PostLogger.new);
ps.putAtom(\one, Pob(\note, 1, \delta, 1)) ;
ps.putAtom(\two, Pob(\note, 2, \delta, 1)) ;
ps.putRule(\root, PSBranch([\one, \one], [\two, \two]));
~ps=ps;
~steps = TestPS.expressPattern(ps);
//~firstpair = (~steps[0..1]).collect(_.note);
//~lastpair = (~steps[2..3]).collect(_.note);
)
~ps;
~steps = TestPS.expressPattern(~ps);
~steps[0..1]
~steps.size;
~ps.root.play;
//Testing:
TestPS.run;