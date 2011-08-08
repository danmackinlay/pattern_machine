(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");

s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthSwarmController.new(s, ~globalOuts);
~control.playGroup;
~control.server;
~control.outBus;
~ind = PSSynthDefPhenotype.newRandom;
~control.playIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthDefPhenotype.newRandom)});
~control.all.do({|a,b,c| [a,b,c].postln;});
Bus.new(\audio, 60, 1).scope;
)

(
~island = PSIsland.new;
//~island.population[22];
//~island.tend;
~island.go;
~island.population.collect({|i| i.fitness})
~island.iterations;
)

/*
NOTES:


TODO:

* provide a way to unwarp as well as warp chromosomes
* support multi-channel listeners (In.ar is hardcoded to 1 channel atm) 
* provide a "migration phase" in which to check for extinction and restock.
* better, binary, mutation operator.
* LFOs
	* support creatures which vocalise only sporadically (saving CPU, or at least saving earspace)
* give lifespans using the exponential distribution \lambda \e ^-\lambda \e
* TODO: scale birthRate and deathRate so that they fit eventual fitness
* reseed population when they all die
* better aging calculations
* sort out the interactions of all these different tick rates and periods.
* Handle "free controls", values that are passed in live by the user. (esp for
	triggers)
	
	* alter chromosome if Specs are changed through UI or any other means, using
		all that Dependent business

* Give the faintest of indications that I do care about tests

* allow custom evolvability mappings and starting chromosome.
* I've just noticed that MCLD has been facing the same problem and made
	classes similar in spirit to mine, as regards selecting the phenotypes
	rather than genotypes, as the NLTK does:
	http://www.mcld.co.uk/supercollider/ - see also https://github.com/howthebodyworks/MCLD_Genetic
* do free/cleanup logic
* normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
* less arbitrary immigration
* consistently use either class or instance methods for selection/mutation
	operators

CREDITS:
Thanks to Martin Marier and Crucial Felix for tips that make this go, and
James Nichols for the peer pressure to do it.


*/

