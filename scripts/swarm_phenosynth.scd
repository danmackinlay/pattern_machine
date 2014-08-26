ServerTreeGui.makeWindow(s);

////////////
// Making a sampler fitnessy thing.
////////////

//initialisation
Server.default = s = Dan.serverboot(\local, \motu);
Server.default = s = Dan.serverboot(\local, \builtin);
Server.default = s = Dan.serverboot(\internal, \motu);
Server.default = s = Dan.serverboot(\internal, \builtin);
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
	//~targetbus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
	/* or THIS */
	/*******************/
	~targetbus = Bus.new(\audio, 1, 1, s);
	s.sync;
	~target = Synth.new(\ps_reson_saw, [\outbus, ~targetbus, \gate, 1, \ffreq, 800, \amp, 1, \pitch, 500, \rq, 0.2], target: ~phenogroup, addAction:\addToHead);
	//~target = Synth.new(\ps_sine, [\outbus, ~targetbus, \gate, 1, \amp, 1, \pitch, 500], target: ~phenogroup, addAction:\addToHead);
	~spy=SpyBus.new.play(~target, ~targetbus);
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
	~factory = PSSynthDefPhenotypeFactory.new(synthDef:\ps_sample_grain, synthArgMap: (\amp: \unipolar.asSpec));
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 50, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 1, \clockRate: 1, \individualConstructor: ~factory, \log: ~log));

	~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollRate:1,  leakCoef:0.5, maxPop:45);
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	~control.listenSynthDef = \ps_judge_fft_wide_distance;
	//~control.listenSynthDef = \ps_judge_fft_narrow_distance;
	//~control.listenSynthDef = \ps_judge_convolution_distance;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	//~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.leakCoef;
	~control.play(~phenogroup, outbus: ~globalOuts, targetbus: ~targetbus);
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
~control.outbus;
~control.playBusses;
~control.fitnessBusses;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 800, \amp, 1, \pitch, 500, \rq, 0.2]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.population.asArray[0];
//when you are bored, do a
~island.free;
~target.free;
~targetbus.free;
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
FreqScope.new(busNum:~targetbus);
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
(
PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]);
PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \amp, 1, \pitch, 800, \rq, 0.002]);
PSSynthDefPhenotype.synthArgsAsChromosome(PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]));
PSSynthDefPhenotype.chromosomeAsSynthArgs(PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \amp, 1, \pitch, 800, \rq, 0.01]));
)


//initialisation
Server.default = s = Dan.serverboot(\local, \motu);
Server.default = s = Dan.serverboot(\local, \builtin);
Server.default = s = Dan.serverboot(\internal, \motu);
Server.default = s = Dan.serverboot(\internal, \builtin);
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
	//~targetbus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
	/* or THIS */
	/*******************/
	~targetbus = Bus.new(\audio, 1, 1, s);
	s.sync;
	~target = Synth.new(\ps_reson_saw, [\outbus, ~targetbus, \gate, 1, \ffreq, 800, \amp, 1, \pitch, 500, \rq, 0.2], target: ~phenogroup, addAction:\addToHead);
	//~target = Synth.new(\ps_sine, [\outbus, ~targetbus, \gate, 1, \amp, 1, \pitch, 500], target: ~phenogroup, addAction:\addToHead);
	~spy=SpyBus.new.play(~target, ~targetbus);
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
	//~control.listenSynthDef = \ps_judge_fft_wide_distance;
	//~control.listenSynthDef = \ps_judge_fft_narrow_distance;
	//~control.listenSynthDef = \ps_judge_convolution_distance;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.leakCoef;
	~control.play(~phenogroup, outbus: ~globalOuts, targetbus: ~targetbus);
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
~control.outbus;
~control.playBusses;
~control.fitnessBusses;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 800, \amp, 1, \pitch, 500, \rq, 0.2]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.population.asArray[0];
//when you are bored, do a
~island.free;
~target.free;
~targetbus.free;
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
FreqScope.new(busNum:~targetbus);
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
(
PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]);
PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \amp, 1, \pitch, 800, \rq, 0.002]);
PSSynthDefPhenotype.synthArgsAsChromosome(PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]));
PSSynthDefPhenotype.chromosomeAsSynthArgs(PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \amp, 1, \pitch, 800, \rq, 0.01]));
)

/**************************
 * Debugging bits
 **************************/

//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//It's all happening here at the moment
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////

//Check sanity on DSP-based comparers
Server.default = s = Dan.serverboot(\internal, \builtin);
StartUp.run;
(
fork {
	~bothSignals = Bus.new(\audio, 0, 2, s);
	s.sync;
	~observedBus = Bus.newFrom(~bothSignals, 0, 1);
	~targetbus = Bus.newFrom(~bothSignals, 1, 1);//Bus.audio(s, 1);
	~matchOut = Bus.control(s, 1);
	~voxgroup = Group.new(s);
	s.sync;
	[~observedBus, ~matchOut, ~voxgroup, ~targetbus].postln;
	~outgroup = Group.after(~voxgroup);
	s.sync;
	0.1.wait;
	~template = Synth.new(\ps_reson_saw, [\outbus, ~targetbus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \amp, 0.5], target: ~voxgroup);
	~candidate = Synth.new(\ps_reson_saw, [\outbus, ~observedBus, \gate, 1, \pitch, 800, \ffreq, 1000, \rq, 0.5, \amp, 0.5], target: ~voxgroup);
	//~comparer = Synth.new(\ps_judge_fft_narrow_distance, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0], target: ~outgroup);
	~comparer = Synth.new(\ps_judge_fft_wide_distance, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_convolution_distance, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_convolution_distance_norm, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_mfcc_distance, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0.0], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_cepstral_distance, [\observedbus, ~observedBus, \targetbus, ~targetbus, \outbus, ~matchOut, \i_leak, 0.0], target: ~outgroup);

	Routine.new({
		while( true, {~matchOut.get(_.postln);
		1.yield;})
	}).play;
 	{
		//FreqScope.new(busNum:~targetbus);
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
~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \amp, 0.5);
~candidate.set(\pitch, 800, \ffreq, 800, \rq, 0.3, \amp, 0.5);
~candidate.set(\pitch, 300, \ffreq, 200, \rq, 0.8, \amp, 0.5);
~candidate.set(\pitch, 600, \ffreq, 600, \rq, 0.3, \amp, 0.5);
~candidate.set(\pitch, 27, \ffreq, 1200, \rq, 0.1, \amp, 0.5);
/*~candidate.autogui(specs:(
	\freq: [20, 20000, \exp, 1, 440],
	\ffreq: [100, 10000, \exp, 1, 440],
	\rq: [0.01, 1, \exp, 1, 0.3]
)*/
)
(
//How the listening controller works, nuts-and-bolts
//Server.default = s = Dan.serverboot(\local, \builtin);
Server.default = s = Dan.serverboot(\internal, \builtin);
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(numChannels:1, fitnessPollRate:1, leakCoef:0.5, maxPop:40);
~control.play(s, outbus: ~globalOuts);
//~ind = PSSynthDefPhenotype.newRandom(4);
//~control.playIndividual(~ind);
//~control.freeIndividual(~ind);
//~ind.chromosomeAsSynthArgs;
//~ind.identityHash;
//~ind.chromosome;
10.do({~control.playIndividual(PSSynthDefPhenotype.newRandom(4))});
~control.all.do({|a,b| [a,b].postln;});
~control.updateFitnesses;
~control.all.collect({|indDict, key| [indDict, key]});
~control.all.values.collect({|indDict| indDict.phenotype.fitness});
~control.free;
)
//ultra-simple debugging synths.
Server.default = s = Dan.serverboot(\internal, \builtin);
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
	~control.play(~phenogroup, outbus: ~globalOuts, targetbus: nil);
	s.sync;
	~factory = PSSynthDefPhenotypeFactory.new(synthDef:\ps_dc, synthArgMap:(\amp: \unipolar.asSpec));
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 50, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 1, \clockRate: 1, \individualConstructor: ~factory, \log: ~log));
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
~control.outbus;
~control.playBusses;
~control.playBusses.get;
~control.fitnessBusses;
~control.fitnessBusses.get;
~control.fitnessBusses.getnSynchronous(6);
~control.all.keys.asArray[0];
~control.all.asArray.dump;
~control.listenGroup;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 500, \amp, 1, \pitch, 500, \rq, 1.0]));
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
Server.default = s = Dan.serverboot(\internal, \builtin);
(
fork {
	~observedBus = Bus.audio(s, 1);
	~dummyBus = Bus.audio(s, 1);
	~fitnessBus = Bus.control(s, 1);
	s.sync;
	~observed = Synth.new(\ps_dc, [\amp, 0.63, \outbus, ~observedBus, \gate, 1], target: s);
	s.sync;
	~comparer = Synth.new(\ps_judge_return_observed, [\observedbus, ~observedBus, \targetbus, ~dummyBus, \outbus, ~fitnessBus, \active, 1, \t_reset, 0, \i_leak, 0.0], target:~observed, addAction:\addAfter);
	s.sync;
	~fitnessBus.get;
};
)
(
~fitnessBus.getSynchronous;
~observed.
)