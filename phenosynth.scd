(
//initialisation
Server.default = s = Server.internal;
//Server.default = s = Server.local;
s.boot;
s.reboot;
StartUp.run;
~globalOuts = Bus.new(\audio, 0, 2);
~globalOuts.scope;
~voxgroup = Group.new(s);
~outgroup = Group.after(~voxgroup);

/*******************/
/* Do either THIS: */
//better way to get first audio in?
//~globalIns = Bus.new(\audio, s.options.numOutputBusChannels, 1);

/* or THIS */
/*******************/
~globalIns = Bus.audio(s, 1);
{|freq=500| SinOsc.ar(freq, 0, 0.3) }.play(target: ~voxgroup, outbus: ~globalIns, addAction:\addBefore)
/*******************/
~globalIns.scope;
//limiter, to avoid little accidents
~limidef = SynthDef.new(\limi,{|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).send;
~limi = Synth.tail(~outGroup, \limi, [~globalOuts]);
//s.volume.gui;
s.volume.volume= -20;
//actual real work now: first choose the controller that will manage the synths
//~control = PSCompareSynthController.new(s, bus:~globalOuts, numChannels:1, fitnessPollInterval:1, templateBus: ~globalIns);
~control = PSCompareSynthController.new(s, bus:~globalOuts, numChannels:1, fitnessPollInterval:1, templateBus: ~globalIns);//now set up the "island" that will control their evolution
~control.listenSynth = \_ga_judge_pitchampmatch;
~island = PSControllerIsland((\population: 50, \mutationProb: 0.1, \mutationSize: 0.7, \initialChromosomeSize: 4), controller:~control);
~island.play;
~island.params;
~island.population;
//listen for a while.
//when you are bored, do a
~island.free;
//testing that things are going OK:
(~island.cookedFitnesses.keys - (~island.rawFitnesses.keys)).size;
(~island.population - (~island.rawFitnesses.keys)).size;
(~island.population - (~island.cookedFitnesses.keys)).size;
(
var best, worst, ranked;
ranked = ~island.rankedPopulation;
best = ranked[0];
worst = ranked[ranked.size-1];
[~island.rawFitnesses[best],~island.cookedFitnesses[best], best.chromosomeAsSynthArgs].postln;
[~island.rawFitnesses[worst],~island.cookedFitnesses[worst], worst.chromosomeAsSynthArgs].postln;
)
[~island.population.size, ~island.rankedPopulation.size, ~island.cookedFitnesses.size, ~island.rawFitnesses.size];
~island.rankedPopulation[0].chromosomeAsSynthArgs;
//these should only ever differ momentarily
~island.population.select(_.wallClockAge>0)
~island.controller.all[~island.population[0].identityHash].playBus.scope;
FreqScope.new(busNum:~island.controller.all[~island.population[0].identityHash].playBus);
FreqScope.new(busNum:~globalIns);
~globalIns
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
)
/**************************
 * TODO
 **************************

* make sure gate is set right.
* right now the test script doesn't especially converge to 800 Hz, even over
  large timescales. Is Synth selection horribly broken?
  
  * manual polyploidy?

* infrastructure

  * augment all protocols to pass in the PSIsand instance, or some global
    state, or both
  * optionally conduct evolution in a Routine which yields from time to time 
    to facilite realtime use
  * move Bus allocation into PS*Controller play methods
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * allow custom evolvability mappings and starting chromosome.
  * plots and histograms of values
  * create own bus allocator, so ouput may be multitrack recorded
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
    simulated in DSP. (I.e. keep a much larger population, but only simulate a part
    of them at once)
  *support geographical separation of populations to aid speciation
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
* go to generalised Feynman-Kac particle filtering methods http://www.math.u-bordeaux1.fr/~delmoral/simulinks.html
* multi-server controllers
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
(
//initialisation
Server.default = s = Server.internal;
//Server.default = s = Server.local;
s.boot;
StartUp.run;
~globalOuts = Bus.new(\audio, 0, 2);
~matchOut = Bus.control(s, 1);
~globalOuts.scope;
~voxgroup = Group.new(s);
~outgroup = Group.after(~voxgroup);
~globalIns = Bus.audio(s, 1);
~template = {|freq=500| SinOsc.ar(freq, 0, 0.3); }.play(target: ~voxgroup, outbus: ~globalIns, addAction: \addToHead, args: [\freq, 600]);
~candidate = Synth.new(\ps_reson_saw, [\out, ~globalOuts, \gate, 1, \pitch, 800, \ffreq, 1000, \rq, 0.5, \gain, 1.0], target: ~voxgroup);
~comparer = Synth.new(\_ga_judge_fftmatch, [\testbus, ~globalOuts, \templatebus, ~globalIns, \out, ~matchOut], target: ~outgroup);
Routine.new({
	while( true, {~matchOut.get(_.postln);
	1.yield;})
}).play;
FreqScope.new(busNum:~globalIns);
~candidate.set(\pitch, 600);
~candidate.set(\ffreq, 600);
~candidate.set(\rq, 0.001);
~candidate.set(\gain, 1);

~candidate.autogui;
)

)
(
~island = PSIsland.new((\initialChromosomeSize: 4));
~island.params;
// Solve sin(3wx\pi/2) = cos(yz\pi)
~island.fitnessEvaluator = [\phenosynth, \fitness_evals, \trigonometry];
~island.fitnessCooker = [\phenosynth, \fitness_cookers, \zero_peak];
~island.play;
~island.population;
~arbitrary = ~island.population.asArray[0];
//~island.init;
~island.rawFitnesses;
~island.rawFitnesses[~arbitrary];
~island.cookedFitnesses[~arbitrary];
~island.cookedFitnesses.values;
~arbitrary.chromosome;
# a, b, c, d = ~arbitrary.chromosome;
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
~island.rawFitnesses;
~island.rawFitnesses.mean;
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
SynthDef.new(\sawy, {|out, freq=200, ffreq=300, rq=0.3| Out.ar(out, BPF.ar(Saw.ar(freq), ffreq, rq));}).add;
~play = Synth.new(\sawy, [\out, ~audioBus, \freq, 300], ~playGroup);
~judge = Synth.new(\ps_conv_eight_hundred, [\in, ~audioBus, \out, ~fitBus, \i_leakcoef, 0.5], ~listenGroup);
~play.set(\freq, 850);
Routine.new({true.while({ 1.yield; ~fitBus.get(_.postln);});}).play;
~play.autogui(specs:(
	\freq: [20, 20000, \exp, 1, 440],
	\ffreq: [100, 10000, \exp, 1, 440],	
	\rq: [0.01, 1, \exp, 1, 0.3]
));
