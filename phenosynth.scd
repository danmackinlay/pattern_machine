(
//initialisation
Server.default = s = Server.internal;
//Server.default = s = Server.local;
s=Server.default;
Phenosynth.reInit;
~globalOuts = Bus.new(\audio, 0, 2);
~globalOuts.scope;
//better way to get first audio in?
~voxgroup = Group.new(s);
~outgroup = Group.after(~voxgroup);

/*******************/
/* Do either THIS: */
//~globalIns = Bus.new(\audio, s.options.numOutputBusChannels, 1);

/* or THIS */
/*******************/
~globalIns = Bus.audio(s, 1);
{|freq=500| SinOsc.ar(freq, 0, 0.3) }.play(target: ~voxgroup, outbus: ~globalIns, addAction:\addBefore)
/*******************/

//limiter, to avoid little accidents
~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send;
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
//s.volume.gui;
s.volume.volume= -20;
//actual real work now: first choose the controller that will manage the synths
~control = PSCompareSynthController.new(s, bus:~globalOuts, numChannels:1, fitnessPollInterval:1, templateBus: ~globalIns);
//now set up the "island" that will control their evolution
~island = PSControllerIsland((\population: 50, \mutationProb: 0.1, \mutationSize: 0.7), controller:~control);
~island.play;
~island.params;
~island.population;
//listen for a while.
//when you are bored, do a
~island.free;
//testing that things are going OK:
~island.population.collect(_.fitness);
~island.fitnesses;
~island.fitnesses.mean;
~island.population;
~island.population.select(_.wallClockAge>0)
//these should only ever differ momentarily
~island.population[0].chromosomeAsSynthArgs;
~island.population[0].chromosome;
~island.controller.all[~island.population[0].identityHash].playBus.scope;
FreqScope.new(busNum:~island.controller.all[~island.population[0].identityHash].playBus);
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
)
/**************************
 * TODO
 **************************

* right now the test script doesn't especially converge to 800 Hz, even over
  large timescales. Is Synth selection horribly broken?
  
  * manual polyploidy?

* infrastructure

  * change fitness protocol to evaluate all at once (so that we can do, e.g.
    ranked selection ), or perhaps just augment it...
  * augment all protocols to pass in the PSIsand instance, or some global
    state, or both
  * move Bus allocation into PS*Controller play methods
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * allow custom evolvability mappings and starting chromosome.
  * plots and histograms of values
  * Fix leaks  
  
    * ensure Groups are also freed.
    * remove debugging cruft when this all works - specifically,
      allocatedNodes and freedNodes member vars on the controller.
    * They seemed to have magically fixed themselves in SC 3.5 beta 2. Remove
      debug code?
  * allow tagging - speciation based on acquiring the right "tag" variable.
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
  * examples of using this to do vanilla non-accumulating, genotype-style selection
  * serialize phenotypes to disk so evolution can be resumed.
  * chromosome management
  
    * go to all-binary chromosomes for increased happiness and elegance.
    * although increased difficulty in doing gradient ascent.
    * or just create handy new classes to cast as needed. (UnsignedUnitFloat,
      and a Genome class.)
    
  * provide a "migration phase" in which to check for extinction and restock.

* Give the faintest of indications that I do care about tests
* document classes
* provide examples
* my earswarm

  * normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
  * evolve a map between input and output to teach creatures to produce maximally
    versatile responses to diverse signals
  * LFOs
  
    * support creatures which vocalise only sporadically (saving CPU, or at
      least saving earspace)

  * give lifespans using the exponential distribution \lambda \e ^-\lambda \e
  * doesn't apply ATM but might with different regimes:
  
    * scale birthRate and deathRate so that they fit eventual fitness
    * reseed population when they all die
*/

/**************************
 * Debugging bits
 **************************/
d=(\aa:2);
d.keys.asArray.collect({|i,j| [i, j].postln;});
(
~island = PSIsland.new((\genomeSize: 4));
~island.params;
//~island.params.stopIterations=1;
// Solve sin(3wx\pi/2) = cos(yz\pi)
~spine = {|a0, a1, a2, a3|
	(2 - 
		((
			((a0*a1*pi).cos) -
			((a2*a3*pi*3/2).sin)
		).abs)
	).max(0);
};
~island.fitnessEvaluator = {|params, phenotype|
	phenotype.chromosome.postln;
	~spine.value(*phenotype.chromosome).postln;
};
~island.play;
~best = ~island.population[0];
~island.population[0].fitness;
~spine.value(*~best.chromosome);
# a, b, c, d = ~best.chromosome;
(a*b*pi).cos;
(c*d*pi*3/2).sin;
)
(
//How the listening controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(s, ~globalOuts);
~ind = PSSynthPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthPhenotype.newRandom)});
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
~control = PSListenSynthController(s, ~globalOuts);
//now set up the "island" that will control their evolution
~island = PSControllerIsland.new((\population: 100, \mutationProb: 0.1, \mutationSize: 0.7), controller:~control);
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
