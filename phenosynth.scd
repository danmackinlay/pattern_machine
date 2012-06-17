//initialisation
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
StartUp.run;
//ServerTreeGui.makeWindow;
s.getQueryTree;
s.queryAllNodes;
(
fork {
~globalOuts = Bus.new(\audio, 0, 2);
//{~globalOuts.scope;}.defer;
~phenogroup = Group.new(s);
s.sync;
~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
~outgroup = Group.new(~phenogroup,  addAction: \addToTail);
~log = PostLogger.global;
//~log = FileLogger.global;
s.sync;
/*******************/
/* Do either THIS: */
//better way to get first audio in?
//~targetBus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
/* or THIS */
/*******************/
~targetBus = Bus.audio(s, 1);
s.sync;
//~target = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \ffreq, 800, \gain, 1, \pitch, 500, \rq, 0.2], target: ~phenogroup, addAction:\addToHead);
~target = Synth.new(\ps_sine, [\out, ~targetBus, \gate, 1, \gain, 1, \pitch, 500], target: ~phenogroup, addAction:\addToHead);
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
//~control = PSCompareSynthController.new(s, bus:~globalOuts, numChannels:1, fitnessPollInterval:1, targetBus: ~targetBus);
~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollInterval:1, leakCoef:0.5, maxPop:40);
//~control.listenSynthDef = \ps_judge_pitchamp_distance;
~control.listenSynthDef = \ps_judge_pitch_distance;
//~control.listenSynthDef = \ps_judge_fft_distance;
//~control.listenSynthDef = \ps_judge_convolution;
//~control.listenSynthDef = \ps_judge_cepstral_distance;
//~control.listenSynthDef = \ps_judge_mfcc_distance;
~control.leakCoef;
~control.play(~phenogroup, outBus: ~globalOuts, targetBus: ~targetBus);
s.sync;
1.wait;
//now set up the "island" that will control their evolution
~island = PSControllerIsland((\populationSize: 40, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 4, \pollPeriod: 1), log: ~log);
//~island.scoreCooker = #[phenosynth, score_cookers, raw];
~island.scoreCooker = #[phenosynth, score_cookers, zero_peak];
//~island.scoreCooker = [\phenosynth, \score_cookers, \reverse_ranked];
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
~control.jackNodes[5].trace;
//~control.jackNodes[3].trace;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
~control.listenGroup;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 500, \gain, 1, \pitch, 500, \rq, 1.0]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.population.asArray[0];
//when you are bored, do a
~island.free;
~island.cookedFitnesses;
~island.cookedFitnesses.values.postln;
~island.cookedFitnesses.size;
~island.rawScores.values.postln;
~island.rawScores.size;
~island.rawScores.keys.asArray[1].hash.asHexString
Library.atList([\phenosynth, \score_cookers, \zero_peak]).value(nil, ~island.rawScores);
Library.atList([\phenosynth, \score_cookers, \reverse_ranked]).value(nil, ~island.rawScores);
~island.scoreCooker.value(nil, ~island.rawScores);
~island.cookedFitnesses;
~cooker.value(nil, ~island.rawScores);
//testing that things are going OK:
(~island.cookedFitnesses.keys - (~island.rawScores.keys)).size;
(~island.population - (~island.rawScores.keys)).size;
(~island.population - (~island.cookedFitnesses.keys)).size;
(
var best, worst, ranked;
ranked = ~island.rankedPopulation;
best = ranked[0];
worst = ranked[ranked.size-1];
[\best, ~island.rawScores[best],~island.cookedFitnesses[best], best.chromosomeAsSynthArgs].postln;
[\worst, ~island.rawScores[worst],~island.cookedFitnesses[worst], worst.chromosomeAsSynthArgs].postln;
nil;
)
~ind = ~island.rankedPopulation[0].chromosomeAsSynthArgs;
~ind
[~island.population.size, ~island.rankedPopulation.size, ~island.cookedFitnesses.size, ~island.rawScores.size];
~island.rankedPopulation[0].chromosomeAsSynthArgs;
//these should only ever differ momentarily
~island.population.select(_.wallClockAge>0)
~island.controller.all[~island.population[0].identityHash].playBus.scope;
FreqScope.new(busNum:~island.controller.all[~island.population[0].identityHash].playBus);
FreqScope.new(busNum:~targetBus);
~targetBus
//~island.controller.all[~island.population[0].identityHash].playBus.spectrogram
(
PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]);
PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.002]);
PSSynthDefPhenotype.synthArgsAsChromosome(PSSynthDefPhenotype.chromosomeAsSynthArgs([0.0, 0.25, 0.75, 1]));
PSSynthDefPhenotype.chromosomeAsSynthArgs(PSSynthDefPhenotype.synthArgsAsChromosome([\ffreq, 800, \gain, 1, \pitch, 800, \rq, 0.01]));
)
)
/**************************
 * TODO
 **************************

* make sure gate is set right.
* right now the test script doesn't especially converge to 500 Hz, even over
  large timescales. Is Synth selection horribly broken?
  
  * at least, my synth output is broken. /actually/ similar sounds score poorly.
  * manual polyploidy?
  * fitness bus is all wrong? (not control, nor not right controlbus?)

* infrastructure

  * create a factory class for phenotypes to avoid need for subclassing
  * offset occasionally ends up nil in decorateIndividualDict, causing alloc to choke
  * augment all operator protocols to pass in the PSIsand instance, or some other global
    state
  * listensynthdefs are primitive compared to comparesynthdefs. Bring them up to date
  * better locking around tending processes,  or better trapping for nils
  * for non-realtime use, optionally conduct evolution in a Routine which yields from
    time to time to facilitate responsiveness
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * allow custom evolvability mappings and starting chromosome.
  * plots and histograms of values
  
    * updated to use Till's ScatterView class rather than SC's lame native plot
      method (which does not support parent args to re-use the GUI or scale). As
       Bill Tozier points, out, 'tis better to use scatter plots or
      similar rich displays for GAs
  
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
  
  * better fitness metrics for listening
  
  	* time-delayed correlation?
  	* amplitude-weighted convolution
  	* some fancy wavelet shit?
  	* FFT comparison is broken at the moment, returns universally 0.
  
  * support geographical separation of populations to aid speciation
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
	~globalOuts = Bus.new(\audio, 0, 1);
	~matchOut = Bus.control(s, 1);
	~voxgroup = Group.new(s);
	~targetBus = Bus.new(\audio, 1, 1);//Bus.audio(s, 1);
	s.sync;
	[~globalOuts, ~matchOut, ~voxgroup, ~targetBus].postln;
	{~globalOuts.scope;}.defer;
	~outgroup = Group.after(~voxgroup);
	s.sync;
	0.1.wait;
	~template = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5], target: ~voxgroup);
	~candidate = Synth.new(\ps_reson_saw, [\out, ~globalOuts, \gate, 1, \pitch, 800, \ffreq, 1000, \rq, 0.5, \gain, 0.5], target: ~voxgroup);
	//~comparer = Synth.new(\ps_judge_fft_distance_norm, [\observedbus, ~globalOuts, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.01], target: ~outgroup);
	~comparer = Synth.new(\ps_judge_convolution, [\observedbus, ~globalOuts, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.01], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_mfcc_distance, [\observedbus, ~globalOuts, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.01], target: ~outgroup);
	//~comparer = Synth.new(\ps_judge_cepstral_distance, [\observedbus, ~globalOuts, \targetbus, ~targetBus, \out, ~matchOut, \i_leak, 0.01], target: ~outgroup);
	
	Routine.new({
		while( true, {~matchOut.get(_.postln);
		1.yield;})
	}).play;
	{FreqScope.new(busNum:~targetBus);}.defer;
	s.sync;
	~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain 0.5);
	//~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain 0.5);
	//~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain 0.5);
	//~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain 0.5);
	//{~candidate.autogui;}.defer;
	s.sync;
	~candidate.trace;
	~comparer.trace;
}
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
~control = PSListenSynthController.new(numChannels:1, fitnessPollInterval:1, leakCoef:0.5, maxPop:40);
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
//Check basic convergence on a toy problem
(
	~island = PSIsland.new((\initialChromosomeSize: 4));
	~island.params;
	// Solve sin(3wx\pi/2) = cos(yz\pi)
	~island.scoreEvaluator = [\phenosynth, \score_evals, \trigonometry];
	~island.scoreCooker = [\phenosynth, \score_cookers, \zero_peak];
	~island.play;
	~island.population;
	~arbitrary = ~island.population.asArray[0];
	//~island.init;
	~island.rawScores;
	~island.rawScores[~arbitrary];
	~island.cookedFitnesses[~arbitrary];
	~island.cookedFitnesses.values;
	~arbitrary.chromosome;
	# a, b, c, d = ~arbitrary.chromosome;
	(a*b*pi).cos;
	(c*d*pi*3/2).sin;
)
//calculating the delay in a convolution of a given window size, using impulses.
/*
The answer turns out to be non-simple:
[ delay for, 64, is, 1 ]
[ delay for, 128, is, 65 ]
[ delay for, 256, is, 193 ]
[ delay for, 512, is, 448 ]
[ delay for, 1024, is, 468 ]
[ delay for, 2048, is, 1472 ]
[ delay for, 4096, is, 1537 ]
So - framesize-64 up to 512,  3/4 framesize-64 for 2048.
1024 and 4096 are just a mystery.
Convolution source inspection is probably necessary.
*/
Server.default = s = ~serverboot.(\internal, \builtin);
(
fork {
	~size=4096;
	~rec = Buffer.alloc(s,~size,2);
	~localrec = nil;
	~indexbus=Bus.control(s,1);
	s.sync;
	6.for(12, {|b|
		~framesize = 2.pow(b);
		~tester = {|t_trig=0|
			var pre, observedsig, templatesig, convolved, gate;
			templatesig = DC.ar(1);
			t_trig = Trig1.ar(K2A.ar(t_trig), SampleDur.ir);
			gate = Trig1.ar(t_trig, BufDur.ir(~rec));
			pre = t_trig;
			convolved = Convolution.ar(templatesig, pre, framesize: ~framesize);
			BufWr.ar(
				inputArray: [pre, convolved],
				bufnum: ~rec,
				phase: Phasor.ar(
					trig: t_trig,
					rate: BufRateScale.kr(~rec),
					start: 0,
					end:BufFrames.kr(~rec)
				) * gate + gate -1,//hope this stops recording when gate is over
				loop:0
			);
			IndexInBetween.kr(~rec, in: 0.5);
		}.play(target: s, outbus:~indexbus);
		s.sync;
		~tester.set(\t_trig, 1);
		s.sync;
		~rec.loadToFloatArray(action: {|a|
			~localrec = a.reshape(~size,2);
			//~indexbus.get;
			~presig=Signal.newFrom(~localrec.slice(nil,0));
			~postsig=Signal.newFrom(~localrec.slice(nil,1));
			{~presig.plot(\pre);}.defer;
			{~postsig.plot(\post);}.defer;
			["delay for", ~framesize, "is", ~postsig.indexOfGreaterThan(0)].postln;
		});
		1.wait;
		~tester.free;
		s.sync;
	});
};
)
(
fork {
	~globalOuts = Bus.new(\audio, 0, 2);
	//{~globalOuts.scope;}.defer;
	~phenogroup = Group.new(s);
	s.sync;
	~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
	~outgroup = Group.new(~phenogroup,  addAction: \addToTail);
	~log = NullLogger.global;
	//~log = PostLogger.global;
	//~log = FileLogger.global;
	s.sync;
	/*******************/
	//limiter, to avoid little accidents
	SynthDef.new(\limi, {|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).add;
	s.sync;
	~limi = Synth.after(~phenogroup, \limi, [~globalOuts]);
	s.volume.volume= -20;
	//actual real work now: first choose the controller that will manage the synths
	~control = PSCompareSynthController.new(numChannels:1, log:~log, fitnessPollInterval:1, leakCoef:0.5, maxPop:40);
	~control.listenSynthDef = \ps_judge_return_observed;
	~control.leakCoef;
	~control.play(~phenogroup, outBus: ~globalOuts, targetBus: nil);
	s.sync;
	//now set up the "island" that will control their evolution
	~island = PSControllerIsland((\populationSize: 40, \mutationProb: 0.1, \mutationSize: 0.1, \initialChromosomeSize: 1, \pollPeriod: 1), log: ~log);
	~island.scoreCooker = #[phenosynth, score_cookers, raw];
	~island.play(~control);
	s.sync;
	[\phenogroup, ~phenogroup, \controlgroup, ~control.playGroup, ~control.listenGroup].postln;
};
)
(
~island.controller;
~control.outBus;
~control.playBusses;
~control.fitnessBusses;
~control.all.keys.asArray[0];
~control.all.asArray.dump;
~control.listenGroup;
//add in a good one and see how it survives:
~island.add(PSSynthDefPhenotype.newFromSynthArgs([\ffreq, 500, \gain, 1, \pitch, 500, \rq, 1.0]));
//{~island.plotFitness(raw:true);}.defer;
~island.params;
~island.population.size;
~island.cookedFitnesses;
~island.cookedFitnesses.values.postln;
~island.cookedFitnesses.size;
~island.rawScores.values.postln;
~island.rawScores.size;
~island.rawScores.keys.asArray[1].hash.asHexString
)