//This API is still not quite how I want it, as there is no natural way to refer to rules ahead of their definition yet.
//Unless I have the production system keep a set of rules? JITlib style even?
(
var root, ps = PSProductionSystem(PostLogger.new);
ps.putTerminalOp(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2)) ;
ps.putTerminalOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
ps.putTerminalEvent(\bar, Pbind(\note, Pseq([1,2,3]), \delta, 1)) ;
ps.putPreTerminal(\phrase, [
	1, [\doubleSpeed, \phrase],
	1, [\halfSpeed, \phrase],
	1, [\bar],
]);
~root = ps.putPreTerminal(\root, [1, \phrase.dup(3)]);
Ptrace(~root).play(TempoClock.new(3));
);
~root.play;
