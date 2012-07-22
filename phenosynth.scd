ServerTreeGui.makeWindow(s);

////////////
// Making a sampler fitnessy thing.
////////////

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
	~sampleBuf = Buffer.read(server, 44100*10);
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
	s.volume.volume = -20;
	//actual real work now: first choose the controller that will manage the synths
	~factory = PSSynthDefPhenotypeFactory.new(synthDef:\ps_sample_grain, synthArgMap: (\gain: \unipolar.asSpec));
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 50, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 1, \clockRate: 1, \individualFactory: ~factory, \log: ~log));

	~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollRate:1,  leakCoef:0.5, maxPop:45);
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	~control.listenSynthDef = \ps_judge_fft_distance_wide;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow;
	//~control.listenSynthDef = \ps_judge_convolution;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	//~control.listenSynthDef = \ps_judge_mfcc_distance;
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

* infrastructure

  * Make the fitness cooker API simpler to develop for and test. Plain lists, rather
    than maps, would be better.
  * cause fitness thingies to automatically report fitness, without waiting for /get
    messages
  * reimplement internal population wrangling using ObjectTable.
  * listensynthdefs are primitive compared to comparesynthdefs. Bring them up to date
  * optionally recycle listeners, since deleting and creating them is CPU-heavy
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * allow custom evolvability mappings and starting chromosome.
  * plots and histograms of values

    * update to use GNUPlot class for data rather than SC's lame native plot
      method (which does not support parent args to re-use the GUI or scale). As
      Bill Tozier points, out, 'tis better to use scatter plots or
      similar rich displays for GAs. (Sadly, Till's ScatterView  doesn't seem
      to work in SC 3.5)
    * send data over OSC to some nonparametric estimator somewhere and plot that.

  * Fix leaks

    * ensure Groups are also freed.
    * use Synth doneActions and per-listener groups to free all resources on
      demand
    * remove rebugging loggers

  * fitness improvements

    * work out the stats for proper birth/death hazard processes, fitness-weighted

  * better fitness metrics for listening

    * time-delayed correlation?
    * amplitude-weighted convolution
    * some fancy wavelet shit?
    * optimise out the spectral-domain transforms of the master signal in the fitness business
    * FFT_wide is not very good. If one signal is low frequency the entire thing
      has a low distance, lower even than a perfect match. (Why?) Even the narrowband
      FFT weights rates low-frequency signals implausibly similar. (try wintype:1?)

  * sort out the interactions of all these different tick rates and periods.
  * Handle "free controls", values that are passed in live by the user, or
    external LFOs or data in general. (esp for triggers)
  * serialize phenotypes to disk so evolution can be resumed.
  * chromosome management

    * create handy new classes to cast as needed between int, bits, float. (UnitFloat,
      and a Chromosome class.)

  * Check for extinction and restock.

* Give the faintest of indications that I do care about tests
* document classes
* provide examples

  * examples of using this to do vanilla non-accumulating, genotype-style selection

* Crazy schemes happening no time soon.

    * support geographical separation of populations to aid speciation
    * augment all operator protocols to pass in the PSIsland instance, or some other global
      state
    * for non-realtime use, optionally conduct evolution in a Routine which yields from
      time to time to facilitate responsiveness
    * Have GUI for phenotypes
    * allow tagging - speciation based on acquiring the right "tag" variable.
    * go to generalised Feynman-Kac particle filtering methods
	  http://www.math.u-bordeaux1.fr/~delmoral/simulinks.html
    * allow a seed-bank supporting far more genomes than can be simultaneously
      simulated in DSP. (I.e. keep a much larger population, but only simulate a part
      of them at once)


* multi-server controllers
* my earswarm

  * normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
  * evolve a map between input and output to teach creatures to produce maximally
    versatile responses to diverse signals
  * sampling, playback
  * LFOs

    * support creatures which vocalise only sporadically (saving CPU, or at
      least saving earspace)

  * give lifespans using the exponential distribution \lambda \e ^{-\lambda \e}
  * doesn't apply ATM but might with different regimes:

    * scale birthRate and deathRate so that they fit eventual fitness
    * reseed population when they all die
*/

/**************************
 * Debugging bits
 **************************/

//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//It's all happening here at the moment
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

//Check sanity on DSP-based comparers
Server.default = s = ~serverboot.(\internal, \builtin);
StartUp.run;
(
fork {
	~bothSignals = Bus.new(\audio, 0, 2, s);
	s.sync;
	~observedBus = Bus.newFrom(~bothSignals, 0, 1);
	~targetBus = Bus.newFrom(~bothSignals, 1, 1);//Bus.audio(s, 1);
	~matchOut = Bus.control(s, 1);
	~voxgroup = Group.new(s);
	s.sync;
	[~observedBus, ~matchOut, ~voxgroup, ~targetBus].postln;
	~outgroup = Group.after(~voxgroup);
	s.sync;
	0.1.wait;
	~template = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5], target: ~voxgroup);
	~candidate = Synth.new(\ps_reson_saw, [\out, ~observedBus, \gate, 1, \pitch, 800, \ffreq, 1000, \rq, 0.5, \gain, 0.5], target: ~voxgroup);
	//~comparer = Synth.new(\ps_judge_fft_distance_narrow, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0], target: ~outgroup);
	~comparer = Synth.new(\ps_judge_fft_distance_wide, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_convolution, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_convolution_norm, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_mfcc_distance, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_cepstral_distance, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.0], target: ~outgroup);

	Routine.new({
		while( true, {~matchOut.get(_.postln);
		1.yield;})
	}).play;
 	{
		//FreqScope.new(busNum:~targetBus);
		FreqScope.new(busNum:~observedBus);
	}.defer;
	{
		~bothSignals.scope;
	}.defer;

	s.sync;
	//{~candidate.autogui;}.defer;
	s.sync;
}
)
(
// ~candidate.trace;
// ~comparer.trace;
~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5);
~candidate.set(\pitch, 800, \ffreq, 800, \rq, 0.3, \gain, 0.5);
~candidate.set(\pitch, 300, \ffreq, 200, \rq, 0.8, \gain, 0.5);
~candidate.set(\pitch, 600, \ffreq, 600, \rq, 0.3, \gain, 0.5);
~candidate.set(\pitch, 27, \ffreq, 1200, \rq, 0.1, \gain, 0.5);
/*~candidate.autogui(specs:(
	\freq: [20, 20000, \exp, 1, 440],
	\ffreq: [100, 10000, \exp, 1, 440],
	\rq: [0.01, 1, \exp, 1, 0.3]
)*/
)
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
//ultra-simple debugging synths.
Server.default = s = ~serverboot.(\internal, \builtin);
(
fork {
	~globalOuts = Bus.audio(s, 1);
	//{~globalOuts.scope;}.defer;
	~phenogroup = Group.new(s);
	s.sync;
	~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
	~outgroup = Group.new(~phenogroup,  addAction: \addToTail);
	//~log = NullLogger.global;
	~log = PostLogger.global;
	~log.minPriority=(-2);
	~log.reject(\controlling);
	//~log = FileLogger.global;
	s.sync;
	//actual real work now: first choose the controller that will manage the synths
	~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollRate:1, leakCoef:0.0, maxPop:60);
	~control.listenSynthDef = \ps_judge_return_observed;
	~control.leakCoef;
	~control.play(~phenogroup, outBus: ~globalOuts, targetBus: nil);
	s.sync;
	~factory = PSSynthDefPhenotypeFactory.new(synthDef:\ps_dc, synthArgMap:(\gain: \unipolar.asSpec));
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 50, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 1, \clockRate: 1, \individualFactory: ~factory, \log: ~log));
	//~island.scoreCooker = #[phenosynth, score_cookers, raw];
	~island.scoreCooker = #[phenosynth, score_cookers, rescale];
	//~island.scoreCooker = #[phenosynth, score_cookers, ranked];
	~island.play(~control);
	s.sync;
};
)
(
s.getQueryTree;
s.queryAllNodes;
~island.controller;
~control.outBus;
~control.playBusses;
~control.playBusses.get;
~control.fitnessBusses;
~control.fitnessBusses.get;
~control.fitnessBusses.getnSynchronous(6);
~control.all.keys.asArray[0];
~control.all.asArray.dump;
~control.listenGroup;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 500, \gain, 1, \pitch, 500, \rq, 1.0]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.cookedFitnessMap;
~island.cookedFitnessMap.values.postln;
~island.rawScoreMap.values.postln;
~island.rawScoreMap.size;
~island.rawScoreMap.keys.asArray[1].hash.asHexString;
~island.free;
)
//simpler again. Sanity check individual fitness thingies.
Server.default = s = ~serverboot.(\internal, \builtin);
(
fork {
	~observedBus = Bus.audio(s, 1);
	~dummyBus = Bus.audio(s, 1);
	~fitnessBus = Bus.control(s, 1);
	s.sync;
	~observed = Synth.new(\ps_dc, [\gain, 0.63, \out, ~observedBus, \gate, 1], target: s);
	s.sync;
	~comparer = Synth.new(\ps_judge_return_observed, [\observedbus, ~observedBus, \targetbus, ~dummyBus, \out, ~fitnessBus, \active, 1, \t_reset, 0, \i_leak, 0.0], target:~observed, addAction:\addAfter);
	s.sync;
	~fitnessBus.get;
};
)
(
~fitnessBus.getSynchronous;
~observed.
)