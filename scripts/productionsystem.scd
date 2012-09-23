//This API is still not quite how I want it, as there is no natural way to refer to rules yet.
Unless I have the production system keep a set of rules? JITlib style even?
(
var ps = PSProductionSystem(PostLogger.new);
ps.putRule(\doubleSpeed, Pbind(\delta, Pkey(\delta) / 2) ;
ps.putRule(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2) ;
ps.putRule(\bar, Pbind(\note, Pseq([1,2,3]), \delta, 1) ;
ps.makePreTerminal(\phrase, [
        		1, [\doubleSpeed, \phrase],
        		1, [\halfSpeed, \phrase],
        		1, [\bar],
        	]);
//ps.putRule(\root, Pn(\phrase, 10);
//Ptrace(ruleMap[\root]).play(TempoClock.new(10));
)