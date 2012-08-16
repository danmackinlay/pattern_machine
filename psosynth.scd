ServerTreeGui.makeWindow(s);
//initialisation
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
StartUp.run;
~plotState = SwarmGraph.new(~swarm);
~plotState.stop;
~gui = SwarmGui.new(~swarm, maxFitness:10);
~gui.setParam(\clockRate, 26);
~gui.setParam(\stepSize, 0.05);
~gui.setParam(\selfTracking, 0.0);
~gui.setParam(\groupTracking, 2.0);
~gui.setParam(\momentum, 1.03);
~gui.setParam(\momentum, 0.99);
~gui.setParam(\noise, 0.001);
~gui.setParam(\noise, 0.01);
~gui.setParam(\noise, 0.1);
~gui.setParam(\noise, 1);
~log.minPriority = 1;
~swarm.cookedFitnessMap.values.mean;
~swarm.cookedFitnessMap.values.variance;
~swarm.swarmLagPosSpeed;
~swarm.swarmLagMeanPosition;
~swarm.swarmLagMeanFitness;
~swarm.swarmLagFitnessRate;
~swarm.swarmLagDispersal;
~swarm.swarmMeanFitness;
~swarm.swarmMeanBestFitness;
~swarm.meanFitness;
~targetBus.scope;
(
fork {
	~globalOuts = Bus.new(\audio, 0, 1, s);
	~phenogroup = Group.new(s);
	s.sync;
	~voxgroup = Group.new(~phenogroup, addAction: \addToHead);
	~outgroup = Group.new(~phenogroup, addAction: \addToTail);
	~log = FileLogger.global;
	~log.reject(\controlling);
	~log.reject(\moving);
	~log.minPriority = 1;
	//~targetBus = Bus.newFrom(s.inputBus, 2, 1); //input 3
	//~targetBus = Bus.audio(s, 1); // internal channel
	~targetBus = Bus.new(\audio, 1, 1, s); //right Channel
	//~filename = ~zamples +/+ "music/flute/fluebitz.aiff";
	~filename = ~zamples +/+ "music/26139__wim__gongloop02alleengong.wav";
	//~filename = ~zamples +/+ "music/26140__wim__gongloop02alleengong01.wav";
	~buffer = Buffer.read(s, ~filename, 0);
	s.sync;
	~targetGroup = Group.head(~phenogroup);
	s.sync;
	~targetPattern = Pbind(
		\instrument, \ps_reson_saw,
		\out, ~targetBus,
		//\ffreq, 800,
		\ffreq, Prand([2/3, 3/4, 1, 4/3, 3/2, ], inf)*600,
		\amp, 1,
		\pitch, Prand([2/3, 3/4, 1, 4/3, 3/2, ], inf)*500,
		\rq, 0.2,
		\dur, Pexprand(1, 10, inf),
		\group, ~targetGroup,
		\addAction, 0,
		\legato, Prand([1/2, 1, 2, ], inf)*5,
	).play;
	
	//~spy = SpyBus.new.play(~targetGroup, ~targetBus);
	s.sync;
	//~spy.moveAfter(~targetGroup);
	/*******************/
	//limiter, to avoid little accidents
	SynthDef.new(\limi, {|bus| ReplaceOut.ar(bus, Limiter.ar(In.ar(bus),1,0.1))}).add;
	s.sync;
	~limi = Synth.after(~phenogroup, \limi, [~globalOuts]);
	{
		s.volume.gui;
		s.volume.volume= -6;
	}.defer;
	//actual real work now: first choose the controller that will manage the synths
	~synthName = \ps_sample_grain_lagged;
	~synthArgMap = PSBasicPlaySynths.synthArgMaps[~synthName];
	//~synthArgMap[\windowSize] = ControlSpec.new(minval: 4.reciprocal, maxval: 1, warp: 'exp');
	~factory = PSSynthDefPhenotypeFactory.new(
		synthDef: ~synthName,
		synthArgMap: ~synthArgMap);
	//Weirdly, this seems to work best if the fitnessPollRate is lower than the
	//update rate.
	~control = PSCompareSynthController.new(
		numChannels:1,
		log:~log,
		leakCoef:0.5,
		maxPop:30,
	);
	~control.extraSynthArgs = [\lagtime, 1.0, \buffer, ~buffer];
	~control.leakCoef = 0.05;
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	//~control.listenSynthDef = \ps_judge_fft_distance_wide;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow;
	//~control.listenSynthDef = \ps_judge_convolution;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.play(~phenogroup, outBus: ~globalOuts, targetBus: ~targetBus);
	s.sync;
	1.wait;
	//now set up the "swarm" that will control their evolution
	~swarm = PSLocalOptimisingSwarm(
	//~swarm = PSOptimisingSwarm(
		(\populationSize: 30, 
		\initialChromosomeSize: 7,
		\clockRate: 20,
		\stepSize: 0.01,
		\selfTracking: 0.0,
		\groupTracking: 0.5,
		\momentum: 0.99,
		\neighboursPerNode: 2,
		\log: ~log,
		\individualConstructor: ~factory,
		//\maxdistance: 8, //a good distance for \ps_judge_pitchamp and scale_distance_to_similarity
		\maxdistance: 5, //a good distance for \ps_judge_mfcc_distance and scale_distance_to_similarity
	));
	//~swarm.scoreCooker = #[phenosynth, score_cookers, raw];
	//~swarm.scoreCooker = #[phenosynth, score_cookers, zero_peak];
	//~swarm.scoreCooker = #[phenosynth, score_cookers, scale_distance_to_similarity];
	~swarm.scoreCooker = #[phenosynth, score_cookers, invert_distance_to_similarity];
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
~swarm.neighbourTable;
~control.outBus;
~control.playBusses;
~control.fitnessBusses;
//{~swarm.plotFitness(raw:true);}.defer;
~swarm.params;
~swarm.initialChromosomeFactory.value;
~swarm.individualFactory.value;
~swarm.cookedFitnessMap;
~swarm.cookedFitnessMap.values.postln;
~swarm.rawScoreMap.values.postln;
~swarm.rawScoreMap.keys.asArray[1].hash.asHexString
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
~buffer.plot;
//when you are bored, do a
~swarm.free;
~targetGroup.free;
~targetBus.free;

/**************************
 * TODO
 **************************
 
* multichannel
  * or just one server per channel perhaps?
* update SynthController to have its params accessed through a controller
  so that, e.g. clockrate can change on the fly
* per-voice synth params - e.g. a pan spread.
* pluck individuals out and let them wander back to the swarm
* High-pass output (or at least DC-remove)
* GUI
    * input and output level mix
* update the target to be an evolving synth
	* say, a live audio input
* more interesting objective functions:
	* match a pitch-shifted version of the input
	* or a delayed version
	* Weight total spectral energy of target against particle
	* cepstral measures to favour harmonicity
* meta-optimisation of the meta-heuristic.
	* annealing schedule
	* detecting the need to update noise parameters
		(e.g. decreasing without changing)
	* detecting convergence
	* remember near-global maxima so I know when I've drifted off.
* specific sample synth player
	* How can this sound sparser? Reward silence?
	* sample playing
	* sample recording
* go to MOL ("many optimising liaisons") 
	* choose random peer as neighbour each time
	* update only one at each time
* handle feedback in reverberant environments in some smart way
	* this could be as simple as pitch shifting inputs
* can I get rid of the PSSynthDefPhenotypeFactory now that I have extraSynthArgs in the controller class?
* should I put some methods in there to handle lagtime on the controller?
* visualise this using Quartz Composer
*/
