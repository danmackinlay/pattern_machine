(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");

s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(s, ~globalOuts);
~control.playGroup;
~control.server;
~control.outBus;
~ind = PSSynthDefPhenome([0.5, 0.5, 0.5]);
~control.playIndividual(~ind);
~ind.identityHash;
~ind.chromosome;
~control.all.do({|a,b,c| [a,b,c].postln;});
)


/* TODO:

* provide a way to unwarp as well as warp chromosomes, and look up values of either. 

*/