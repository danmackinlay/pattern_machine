(
//initialisation
Server.default = s = Server.internal;
Server.default = s = Server.local;
s=Server.default;
Phenosynth.reInit;
~globalOuts = Bus.new(\audio, 0, 2);
~globalOuts.scope;
//better way to get first audio in?
~globalIns = Bus.new(\audio, s.options.numOutputBusChannels, 1);~globalIns = Bus.audio(s, 1)
~voxgroup = Group.new(s);
~outgroup = Group.after(~voxgroup);
//limiter, to avoid little accidents
~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send;
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
//s.volume.gui;
s.volume.volume= -20;
//actual real work now: first choose the controller that will manage the synths
~control = PSCompareSwarmController.new(s, bus:~globalOuts, numChannels:1, fitnessPollInterval:1, templateBus: ~globalIns);
//now set up the "island" that will control their evolution
~island = PSSynthSwarmIsland.new((\population: 50, \mutationProb: 0.1, \mutationSize: 0.7), controller:~control);
~island.play;
~control.templateBus;
~control.fitnessPollInterval;
~island.params;
~island.population;
//listen for a while.
//when you are bored, do a
~island.free;
~control.all;
~control.all.size;
~control.freedNodes;
~control.allocatedNodes;
//testing that things are going OK:
~island.population.collect(_.fitness);
~island.fitnesses;
~island.fitnesses.mean;
~island.population;
~island.population.select(_.wallClockAge>0)
~island.population.collect({|i| i.wallClockAge}).mean;
~island.population.collect({|i| i.logicalAge}).mean;
//these should only ever differ momentarily
~island.population.size;
~island.population[0];

~island.population[0].chromosomeAsSynthArgs;
~island.population[0].chromosome;
~island.population[0].synth;
~island.controller.all[~island.population[0].identityHash].playBus.scope
)
/**************************
 * Debugging bits
 **************************

* right now the test script doesn't especially converge to 800 Hz, even over large
  timescales
  
  * manual polyploidy?

* infrastructure

  * allow dynamic (re) assignment of evolutionary operators
  * move Bus allocation into PS*Controller play methods
  * make synth loading methods be consistent (add or writeOnce?)
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * Fix leaks  
    * ensure Groups are also freed.
    * remove debugging cruft when this all works - specifically,
      allocatedNodes and freedNodes member vars on the controller.
    * They seemed to have magically fixed themselves in SC 3.5 beta 2. Remove
      debug code?
  
  * envelope synth deletion
  
    * use Synth doneActions and per-listener groups to free all resources on
      demand
    * don't bother freeing the "jack" synths where population is constant.
    * watch out for those double /n_frees - might break something.
    
  * allow a seed-bank supporting far more genomes than can be simultaneously
    simulated. (I.e. keep a much larger population, but only simulate a part
    of them at once)
  * use wrapping infrastructure to simplify the listensynth definitions.
  
    * support multi-channel listeners (In.ar is hardcoded to 1 channel atm) 

  * sort out the interactions of all these different tick rates and periods.
  * Handle "free controls", values that are passed in live by the user, or
    external LFOs or data in general. (esp for triggers)
  * alter chromosome if Specs are changed through UI or any other means, using
    all that Dependent business
  * support "fitness injection" - doing custom pre-processing on fitness?
  
    * so much more complex than simply overriding the class. do that later.
    
  * non-accumulating, genotype-style selection
  
    * but I don't personally need that.
        
  * serialize phenotypes to disk so evolution can be resumed.
  * chromosome management
  
    * go to all-binary chromosomes for increased happiness and elegance.
    * although increased difficulty in doing gradient ascent.
    * or just create handy new classes to cast as needed. (UnsignedUnitFloat)
    
  * provide a "migration phase" in which to check for extinction and restock.

* Give the faintest of indications that I do care about tests
* my earswarm

  * normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
  * LFOs
  
    * support creatures which vocalise only sporadically (saving CPU, or at
      least saving earspace)
  * give lifespans using the exponential distribution \lambda \e ^-\lambda \e
  * doesn't apply ATM but might with different regimes:
  
    * scale birthRate and deathRate so that they fit eventual fitness
    * reseed population when they all die

* allow custom evolvability mappings and starting chromosome.
* evolve a map between input and output to teach creatures to produce maximally
  versatile responses to diverse signals
* I've just noticed that MCLD has been facing the same problem and made
  classes similar in spirit to mine, as regards selecting the phenotypes
  rather than genotypes, as the NLTK does:
  http://www.mcld.co.uk/supercollider/ - see also 
  https://github.com/howthebodyworks/MCLD_Genetic

CREDITS:
Thanks to Martin Marier and Crucial Felix for tips that make this go, and
James Nichols for the peer pressure to do it.


*/

/**************************
 * Debugging bits
 **************************/
 
(
//How the listening controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSwarmController.new(s, ~globalOuts);
~ind = PSSynthDefPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthDefPhenotype.newRandom)});
~control.all.do({|a,b| [a,b].postln;});
~control.updateFitnesses;
~control.all.collect({|indDict, key| [indDict, key]});
~control.all.values.collect({|indDict| indDict.phenotype.fitness});
~control.free;
)
(
//initialisation
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~globalOuts.scope;
~globalIns = Bus.audio(s, 1)
~voxgroup = Group.new(s);
~outgroup = Group.after(~voxgroup);
//limiter, to avoid little accidents
~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send;
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
//s.volume.gui;
s.volume.volume= -20;
//actual real work now: first choose the controller that will manage the synths
~control = PSListenSwarmController(s, ~globalOuts);
//now set up the "island" that will control their evolution
~island = PSSynthSwarmIsland.new((\population: 100, \mutationProb: 0.1, \mutationSize: 0.7), controller:~control);
~island.play;
~island.params;
~island.population;
//listen for a while.
//when you are bored, do a
~island.free;
~control.all;
~control.all.size;
~control.freedNodes;
~control.allocatedNodes;

//testing that things are going OK:
~island.population.collect(_.fitness);
~island.fitnesses;
~island.fitnesses.mean;
~island.population;
~island.population.select(_.wallClockAge>0)
~island.population.collect({|i| i.wallClockAge}).mean;
~island.population.collect({|i| i.logicalAge}).mean;
//these should only ever differ momentarily
~island.population.size;
~island.population[0];

~island.population[0].chromosomeAsSynthArgs;
~island.population[0].chromosome;
~island.population[0].synth;
~island.controller.all[~island.population[0].identityHash].playBus.scope
~globalOuts.scope
)
(
//test listeners
~playbus = Bus.audio(s, 1);
~fitbus = Bus.control(s, 1);
~eighthundredsource = {|freq=500| SinOsc.ar(freq); }.play(s, outbus: ~playbus)
Synth.after(~eighthundredsource, \ps_conv_eight_hundred, [\in, ~playbus, \out, ~fitbus, \i_leakcoef, 0.5]);
~fitbus.get(_.postln);
~eighthundredsource.set(\freq, 400);
)
(
~playGroup = Group.new(s);
~listenGroup = Group.after(~playGroup);
~audioBus = Bus.audio(s, 1);
~fitBus = Bus.control(s,1);
SynthDef.new(\sawy, {|out, freq| Out.ar(out, Saw.ar(freq));}).add;
~play = Synth.new(\sawy, [\out, ~audioBus, \freq, 300], ~playGroup);
~judge = Synth.new(\ps_conv_eight_hundred, [\in, ~audioBus, \out, ~fitBus, \i_leakcoef, 0.5], ~listenGroup);
~play.set(\freq, 850);
~fitBus.get(_.postln);
)
