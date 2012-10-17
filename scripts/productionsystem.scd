(
var ps = PSProductionSystem(PostLogger.new);
ps.putOp(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2)) ;
ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
ps.putAtom(\bar, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putRule(\phrase, [
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\bar],
]);
~root = ps.putRule(\root, [1, \phrase.dup(3)]);
Ptrace(~root).play(TempoClock.new(3));
);
~root.play;

//Examples
(
var ps = PSProductionSystem(PostLogger.new);
ps.putOp(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2)) ;
ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
ps.putOp(\upThird, Pbind(\note, Pkey(\note) + 4)) ;
ps.putOp(\upFifth, Pbind(\note, Pkey(\note) + 5)) ;
ps.putAtom(\riff, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putRule(\phrase, [
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\upThird, \phrase],
	1, [\upFifth, \phrase],
	2, [\riff],
]);
~root = ps.putRule(\root, [1, \phrase.dup(3)]);
//We want to have this pattern restart every bar, but the Pfindur pattern does not compose; it must operate upon; thus it is imposed from outside;
//this feels a little unsatisfactory
Ptrace(Pn(Pfindur(4,~root),10)).play(TempoClock.new(3));
)


//Testing:
TestPS.run;