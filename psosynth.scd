//initialisation
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
StartUp.run;
(
s.waitForBoot({
	fork {
	var population = 30;
	~swarmOut = Bus.new(\audio, 0, 1, s);
	~phenogroup = Group.new(s);
	//~filename = ~zamples +/+ "music/flute/fluebitz.aiff";
	~filename = ~zamples +/+ "music/26139__wim__gongloop02alleengong.wav";
	//~filename = ~zamples +/+ "music/26140__wim__gongloop02alleengong01.wav";
	~buffer = Buffer.read(s, ~filename, 0);
	SynthDef.new(\limi, {|outbus, cutoff=50, pregain=1|
		ReplaceOut.ar(
			outbus,
			Limiter.ar(
				HPF.ar(
					in: In.ar(outbus),
					freq: cutoff,
					mul: pregain
				),
				1,
				0.01
			)
		)
	}).add;
	~log = FileLogger.global;
	~log.reject(\controlling);
	~log.reject(\moving);
	~log.minPriority = 1;
	s.sync;
	~targetGroup = Group.head(~phenogroup);
	//~targetbus = Bus.newFrom(s.inputBus, 2, 1); //input 3
	~targetbus = Bus.newFrom(s.inputBus, 0, 1); //input 1
	//~targetbus = Bus.audio(s, 1); // internal channel
	//~targetbus = Bus.new(\audio, 1, 1, s); //right Channel
	~voxgroup = Group.head(~phenogroup);
	s.sync;
	/*~targetPattern = Pbind(
		\instrument, \ps_reson_saw,
		\outbus, ~targetbus,
		//\ffreq, 800,
		\ffreq, Prand([2/3, 3/4, 1, 4/3, 3/2, ], inf)*600,
		\amp, 0.1,
		\pitch, Prand([2/3, 3/4, 1, 4/3, 3/2, ], inf)*500,
		\rq, 0.2,
		\dur, Pexprand(5, 20, inf),
		\group, ~targetGroup,
		\addAction, 0,
		\legato, Prand([1/2, 3/4, 1, 3/2, 2,], inf),
	).play;*/
	s.sync;
	//~spy = SpyBus.new.play(~targetGroup, ~targetbus);
	//~spy.moveAfter(~targetGroup);
	//~spy.listenTo(~swarmOut);
	/*******************/
	//limiter, to avoid little accidents
	~limi = Synth.after(~phenogroup, \limi,
		[\outbus, ~swarmOut,
		\pregain, population.sqrt.reciprocal]);
	{
		//s.volume.gui;
		s.volume.volume= -6;
	}.defer;
	//actual real work now: first choose the controller that will manage the synths
	~synthName = \ps_sample_grain_lfo_lagged;
	~synthArgMap = PSBasicPlaySynths.synthArgMaps[~synthName];
	~synthArgMap[\lforate] = ControlSpec.new(minval: 0.25, maxval: 8, warp: 'exp');
	~synthArgMap[\lfoamt] = ControlSpec.new(minval: 0.1, maxval: 1);
	~factory = PSSynthDefPhenotypeFactory.new(
		synthDef: ~synthName,
		synthArgMap: ~synthArgMap);
	//Weirdly, this seems to work best if the fitnessPollRate is lower than the
	//update rate.
	~control = PSCompareSynthController.new(
		numChannels:1,
		log:~log,
		leakCoef:0.5,
		maxPop:population,
	);
	~control.extraSynthArgs = [\lagtime, 0.2, \buffer, ~buffer];
	~control.leakCoef = 0.05;
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitchamp_distance;
	//~control.listenSynthDef = \ps_judge_pitch_distance;
	//~control.listenSynthDef = \ps_judge_fft_distance_wide;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow;
	//~control.listenSynthDef = \ps_judge_convolution;
	//~control.listenSynthDef = \ps_judge_cepstral_distance;
	//~control.listenSynthDef = \ps_judge_mfcc_distance;
	~control.listenSynthDef = \ps_judge_mfcc_distance_amp;
	~control.play(~phenogroup, outbus: ~swarmOut, targetbus: ~targetbus);
	s.sync;
	1.wait;
	//now set up the "swarm" that will control their evolution
	~swarm = PSLocalOptimisingSwarm(
	//~swarm = PSOptimisingSwarm(
		(\populationSize: population, 
		\initialChromosomeSize: 9,
		\clockRate: 20,
		\stepSize: 0.02,
		\selfTracking: 0.0,
		\groupTracking: 1.5,
		\noise: 0.03,
		\momentum: 0.99,
		\neighboursPerNode: 3,
		\log: ~log,
		\individualConstructor: ~factory,
		//\maxdistance: 8, //a good distance for \ps_judge_pitchamp and scale_distance_to_similarity
		//\maxdistance: 5, //a good distance for \ps_judge_mfcc_distance and scale_distance_to_similarity
	));
	//~swarm.scoreCooker = #[phenosynth, score_cookers, raw];
	//~swarm.scoreCooker = #[phenosynth, score_cookers, zero_peak];
	//~swarm.scoreCooker = #[phenosynth, score_cookers, scale_distance_to_similarity];
	~swarm.scoreCooker = #[phenosynth, score_cookers, invert_distance_to_similarity];
	//~swarm.scoreCooker = [\phenosynth, \score_cookers, \reverse_ranked];
	~swarm.play(~control);
	{
		~plotState = SwarmGraph.new(~swarm);
		~gui = SwarmGui.new(~swarm, maxFitness:10);
	}.defer;
	[\phenogroup, ~phenogroup, \controlgroups, ~control.playGroup, ~control.listenGroup].postln;
};
});
)
~plotState.stop;
~buffer.plot
//listen for a while.
//experiment
ServerTreeGui.makeWindow(s);
s.queryAllNodes;

//when you are bored, do a
~swarm.free;
~phenoGroup.free;
~targetbus.free;

/**************************
 * TODO
 **************************
 
* multichannel
  * or just one server per channel perhaps?
  * per-voice synth params - e.g. a pan spread.
* GUI
    * input and output level mix
    * "explode" button, scattering the chromosomes
    * pluck individuals out and let them wander back to the swarm
* update the target to be an evolving synth
	* say, a live audio input
* more interesting objective functions:
	* match a pitch-shifted version of the input
	* or a delayed version
	* cepstral measures to favour harmonicity
	* how the hell does this get to be near-infinite for quiet inputs?
* meta-optimisation of the meta-heuristic.
	* annealing schedule
	* detecting the need to update noise parameters
		(e.g. decreasing without changing)
	* optional meta-optimising operator
	* remember near-global maxima so I know when I've drifted off.
* specific sample synth player
	* How can this sound sparser? Reward silence?
	* lfo?
	* some kind of nonlinear feedback situation?
	* sample recording
* handle feedback in reverberant environments in some smart way
	* this could be as simple as pitch shifting inputs
* go to MOL ("many optimising liaisons") 
	* choose random peer as neighbour each time
	* update only one at each time
* visualise this using Quartz Composer
* update SynthController to have its params accessed through a controller
  so that, e.g. clockrate can change on the fly
* can I get rid of the PSSynthDefPhenotypeFactory now that I have extraSynthArgs in the controller class?
* should I put some methods in there to handle lagtime on the controller?
*/
