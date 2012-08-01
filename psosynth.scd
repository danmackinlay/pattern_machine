ServerTreeGui.makeWindow(s);
//initialisation
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
StartUp.run;

(
~graphSwarm = {|swarm|
	//TODO: implement as "impulses" plot style
	var worker, plotter, population, idhashes;
	var state = ();
	state.population = population = swarm.population.asArray;
	state.idhashes = idhashes = population.collect({|i|
		i.identityHash.asHexString;
	});
	state.plotter = plotter = GNUPlot.new;
	//fitness-relevant axis ranges.
	plotter.sendCmd("set xrange [0:1]");
	plotter.sendCmd("set yrange [0:1]");
	plotter.sendCmd("set zrange [0:]");
	worker = state.worker = Routine.new({
		loop {
			//this plots a 2d slice of the chromosome, using the z axis for fitness
			// of said slice.
			var locs;
			locs = population.collect({|ind|
				//[\ind, ind].postln;
				[ind.chromosome[0..1] ++ swarm.cookedFitnessMap[ind]];
			});
			plotter.scatter(locs, idhashes);
			//state.locs = locs;
			(swarm.params.clockRate.reciprocal).yield;
		};
	}).play(AppClock);
	state;
};
)
~plotState = ~graphSwarm.(~swarm);
~plotState.worker.stop;
~plotState.plotter.stop;
(
fork {
	~globalOuts = Bus.new(\audio, 0, 1, s);
	//{~globalOuts.scope;}.defer;
	~phenogroup = Group.new(s);
	s.sync;
	~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
	~outgroup = Group.new(~phenogroup, addAction: \addToTail);
	//~log = NullLogger.global;
	~log = PostLogger.global;
	//~log = FileLogger.global;
	~log.reject(\controlling);
	~log.minPriority = 0;
	~targetBus = Bus.new(\audio, 1, 1, s);
	s.sync;
	~target = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \ffreq, 800, \gain, 1, \pitch, 500, \rq, 0.2], target: ~phenogroup, addAction:\addToHead);
	//~target = Synth.new(\ps_sine, [\out, ~targetBus, \gate, 1, \gain, 1, \pitch, 500], target: ~phenogroup, addAction:\addToHead);
	~spy = SpyBus.new.play(~target, ~targetBus);
	s.sync;
	//~spy.moveAfter(~target);
	/*******************/
	//limiter, to avoid little accidents
	SynthDef.new(\limi, {|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).add;
	s.sync;
	~limi = Synth.after(~phenogroup, \limi, [~globalOuts]);
	//s.volume.gui;
	s.volume.volume= -20;
	//actual real work now: first choose the controller that will manage the synths
	~factory = PSSynthDefPhenotypeFactory.new(
		synthDef:\ps_reson_saw_lagged);
	~control = PSCompareSynthController.new(
		numChannels:1, log:~log, fitnessPollRate:5, leakCoef:0.5, maxPop:30,
	);
	~control.extraSynthArgs = [\lagtime, 0];
	~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	//~control.listenSynthDef = \ps_judge_fft_distance_wide;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow;
	//~control.listenSynthDef = \ps_judge_convolution;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	//~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.play(~phenogroup, outBus: ~globalOuts, targetBus: ~targetBus);
	s.sync;
	1.wait;
	//now set up the "swarm" that will control their evolution
	~swarm = PSOptimisingSwarm((\populationSize: 30, 
		\chromosomeSize: 4, \clockRate: 2.5, \log: ~log,
		\individualConstructor: ~factory));
	//~swarm.scoreCooker = #[phenosynth, score_cookers, raw];
	~swarm.scoreCooker = #[phenosynth, score_cookers, zero_peak];
	//~swarm.scoreCooker = [\phenosynth, \score_cookers, \reverse_ranked];
	~swarm.play(~control);
	s.sync;
	[\phenogroup, ~phenogroup, \controlgroups, ~control.playGroup, ~control.listenGroup].postln;
};
)
//listen for a while.
//experiment
s.queryAllNodes;
~swarm.controller;
~swarm.params;
~swarm.neighbourTable;
~control.outBus;
~control.playBusses;
~control.fitnessBusses;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
//add in a good one and see how it survives:
~swarm.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 800, \gain, 1, \pitch, 500, \rq, 0.2]));
//{~swarm.plotFitness(raw:true);}.defer;
~swarm.params;
~swarm.initialChromosomeFactory.value;
~swarm.individualFactory.value;
~swarm.population.size;
~swarm.population.asArray[0];
//when you are bored, do a
~swarm.free;
~target.free;
~targetBus.free;
~swarm.cookedFitnessMap;
~swarm.cookedFitnessMap.values.postln;
~swarm.rawScoreMap.values.postln;
~swarm.rawScoreMap.keys.asArray[1].hash.asHexString
Library.atList([\phenosynth, \score_cookers, \zero_peak]).value(nil, ~swarm.rawScoreMap);
Library.atList([\phenosynth, \score_cookers, \reverse_ranked]).value(nil, ~swarm.rawScoreMap);
//testing that things are going OK:
(
var best, worst, ranked;
ranked = ~swarm.rankedPopulation;
best = ranked[0];
worst = ranked[ranked.size-1];
[\best, ~swarm.rawScoreMap[best],~swarm.cookedFitnessMap[best], best.chromosomeAsSynthArgs].postln;
[\worst, ~swarm.rawScoreMap[worst],~swarm.cookedFitnessMap[worst], worst.chromosomeAsSynthArgs].postln;
nil;
)
[~swarm.population.size, ~swarm.rankedPopulation.size, ~swarm.cookedFitnessMap.size, ~swarm.rawScoreMap.size];
//these should only ever differ momentarily
~swarm.population.select(_.wallClockAge>0)
~swarm.controller.all[~swarm.population[0].identityHash].playBus.scope;
FreqScope.new(busNum:~swarm.controller.all[~swarm.population[0].identityHash].playBus);
FreqScope.new(busNum:~targetBus);
//~swarm.controller.all[~swarm.population[0].identityHash].playBus.spectrogram
(
PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]);
PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.002]);
PSSynthDefPhenotype.synthArgsAsChromosome(PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]));
PSSynthDefPhenotype.chromosomeAsSynthArgs(PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.01]));
)
/**************************
 * TODO
 **************************
 
* multichannel
* go to MOL ("many optimising liaisons") - choose random peer as neighbour.
* detecting the need to update noise parameters
* GUI for noise params
* sample playing
* sample reecording
* can I get rid of the PSSynthDefPhenotypeFactory now that I have extraSynthArgs in the controller class?
* should I put some methods in there to handle lagtime on the controller?
* Eliminate the phenotype factory malarkey; it should be all handle by the controller.
*/

/**************************
 * Debugging bits
 **************************/

(
//How the listening controller works, nuts-and-bolts
//Server.default = s = ~serverboot.(\local, \builtin);
Server.default = s = ~serverboot.(\internal, \builtin);
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(numChannels:1, fitnessPollRate:5, leakCoef:0.5, maxPop:40);
~control.play(s, outBus: ~globalOuts);
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
