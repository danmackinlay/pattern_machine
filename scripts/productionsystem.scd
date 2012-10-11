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
TestPS.run;
(
var steps = TestPS.expressSystem(~root);
~root.asStream.nextN(100, Event.default).select(_.notNil);
~root.asStream;
)
