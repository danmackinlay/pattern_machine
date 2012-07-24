ServerTreeGui.makeWindow(s);

//initialisation
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
StartUp.run;
(
fork {
	~globalOuts = Bus.new(\audio, 0, 1, s);
	//{~globalOuts.scope;}.defer;
	~phenogroup = Group.new(s);
	s.sync;
	~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
	~outgroup = Group.new(~phenogroup,  addAction: \addToTail);
	//~log = NullLogger.global;
	~log = PostLogger.global;
	//~log = FileLogger.global;
	~log.reject(\selection);
	~log.accept(\controlling);
	~log.minPriority = 0;
	s.sync;
	/*******************/
	/* Do either THIS: */
	//better way to get first audio in?
	//~targetBus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
	/* or THIS */
	/*******************/
	~targetBus = Bus.new(\audio, 1, 1, s);
	s.sync;
	~target = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \ffreq, 800, \gain, 1, \pitch, 500, \rq, 0.2], target: ~phenogroup, addAction:\addToHead);
	//~target = Synth.new(\ps_sine, [\out, ~targetBus, \gate, 1, \gain, 1, \pitch, 500], target: ~phenogroup, addAction:\addToHead);
	~spy=SpyBus.new.play(~target, ~targetBus);
	//~target.set(\pitch, 500);
	s.sync;
	//~spy.moveAfter(~target);
	//~target.trace;
	/*******************/
	//limiter, to avoid little accidents
	SynthDef.new(\limi, {|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).add;
	s.sync;
	~limi = Synth.after(~phenogroup, \limi, [~globalOuts]);
	//s.volume.gui;
	s.volume.volume= -20;
	//actual real work now: first choose the controller that will manage the synths
	~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollRate:1,  leakCoef:0.5, maxPop:45);
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	//~control.listenSynthDef = \ps_judge_fft_distance_wide;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow;
	//~control.listenSynthDef = \ps_judge_convolution;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.leakCoef;
	~control.play(~phenogroup, outBus: ~globalOuts, targetBus: ~targetBus);
	s.sync;
	1.wait;
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 40, \mutationProb: 0.25, \mutationSize: 0.1, \initialChromosomeSize: 4, \clockRate: 1, \log: ~log, \deathRate: 0.5));
	//~island.scoreCooker = #[phenosynth, score_cookers, raw];
	//~island.scoreCooker = #[phenosynth, score_cookers, zero_peak];
	~island.scoreCooker = [\phenosynth, \score_cookers, \reverse_ranked];
	~island.play(~control);
	s.sync;
	[\phenogroup, ~phenogroup, \controlgroup, ~control.playGroup, ~control.listenGroup].postln;
};
)
//listen for a while.
//experiment
s.queryAllNodes;
~island.controller;
~control.outBus;
~control.playBusses;
~control.fitnessBusses;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 800, \gain, 1, \pitch, 500, \rq, 0.2]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.population.asArray[0];
//when you are bored, do a
~island.free;
~target.free;
~targetBus.free;
~island.cookedFitnessMap;
~island.cookedFitnessMap.values.postln;
~island.rawScoreMap.values.postln;
~island.rawScoreMap.keys.asArray[1].hash.asHexString
Library.atList([\phenosynth, \score_cookers, \zero_peak]).value(nil, ~island.rawScoreMap);
Library.atList([\phenosynth, \score_cookers, \reverse_ranked]).value(nil, ~island.rawScoreMap);
//testing that things are going OK:
(
var best, worst, ranked;
ranked = ~island.rankedPopulation;
best = ranked[0];
worst = ranked[ranked.size-1];
[\best, ~island.rawScoreMap[best],~island.cookedFitnessMap[best], best.chromosomeAsSynthArgs].postln;
[\worst, ~island.rawScoreMap[worst],~island.cookedFitnessMap[worst], worst.chromosomeAsSynthArgs].postln;
nil;
)
[~island.population.size, ~island.rankedPopulation.size, ~island.cookedFitnessMap.size, ~island.rawScoreMap.size];
//these should only ever differ momentarily
~island.population.select(_.wallClockAge>0)
~island.controller.all[~island.population[0].identityHash].playBus.scope;
FreqScope.new(busNum:~island.controller.all[~island.population[0].identityHash].playBus);
FreqScope.new(busNum:~targetBus);
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
(
PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]);
PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.002]);
PSSynthDefPhenotype.synthArgsAsChromosome(PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]));
PSSynthDefPhenotype.chromosomeAsSynthArgs(PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.01]));
)
/**************************
 * TODO
 **************************


*/

/**************************
 * Debugging bits
 **************************/

(
//How the listening controller works, nuts-and-bolts
//Server.default = s = ~serverboot.(\local, \builtin);
Server.default = s = ~serverboot.(\internal, \builtin);
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(numChannels:1, fitnessPollRate:1, leakCoef:0.5, maxPop:40);
~control.play(s, outBus: ~globalOuts);
//~ind = PSSynthPhenotype.newRandom(4);
//~control.playIndividual(~ind);
//~control.freeIndividual(~ind);
//~ind.chromosomeAsSynthArgs;
//~ind.identityHash;
//~ind.chromosome;
10.do({~control.playIndividual(PSSynthPhenotype.newRandom(4))});
~control.all.do({|a,b| [a,b].postln;});
~control.updateFitnesses;
~control.all.collect({|indDict, key| [indDict, key]});
~control.all.values.collect({|indDict| indDict.phenotype.fitness});
~control.free;
)
