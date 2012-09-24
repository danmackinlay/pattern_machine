//initialisation
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \builtin);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\local, \builtin);
StartUp.run;
~control.setAll(\buffer, ~buffers[1]);
~control.setAll(\buffer, ~buffers[4]);
~control.setAll(\buffer, ~buffers[5]);
~control.setAll(\buffer, ~buffers[7]);
~swarm.randomize;
(
s.waitForBoot({
	fork {
	var population = 30;
	~swarmOut = Bus.new(\audio, 0, 1, s);
	~phenogroup = Group.new(s);
	~fileNames = ([
		"music/flute/mixedflute-chang-cleaned.wav",
		"music/flute/ucdahdahdahdah.aif",
		"music/flute/justflute-chang-cleaned.wav",
		"music/brass/sarah-miniblues-trumpet.aif.wav",
		"music/26140__wim__gongloop02alleengong01.wav",
		"animal/alice bees2.wav",
		"animal/swan view squawks-denoise.wav",
		"animal/driftingchirps.MP3.aiff",
	]).collect(~zamples +/+ _);
	~buffers = ~fileNames.collect(Buffer.read(s, _, 0));
	~log = FileLogger.global;
	~log.reject(\controlling);
	~log.reject(\moving);
	~log.minPriority = 1;
	s.sync;
	~targetGroup = Group.head(~phenogroup);
	~targetbus = Bus.newFrom(s.inputBus, 2, 1); //input 3
	//~targetbus = Bus.newFrom(s.inputBus, 0, 1); //input 1
	//~targetbus = Bus.audio(s, 1); // internal channel
	//~targetbus = Bus.new(\audio, 1, 1, s); //right Channel
	~voxgroup = Group.head(~phenogroup);
	s.sync;
	/*~targetPattern = Pbind(
		\instrument, \ps_reson_saw,
		\outbus, ~targetbus,
		//\ffreq, 800,
		\ffreq, Prand([1/6, 1/4, 1,3, 1/2, 2/3, 3/4, 1], inf)*500,
		\amp, 0.1,
		\pitch, Prand([1/6, 1/4, 1,3, 1/2, 2/3, 3/4, 1], inf)*400,
		\rq, 0.5,
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
	~limi = Synth.after(~phenogroup, \limi__2,
		[\outbus, ~swarmOut,
		\pregain, population.sqrt.reciprocal*8,
		\cutoff, 40]);
	{
		//s.volume.gui;
		//s.volume.volume= -6;
	}.defer;
	//actual real work now: first choose the controller that will manage the synths
	~synthName = \ps_sample_grain_lagged_pan2;
	~synthArgMap = PSBasicPlaySynths.synthArgMaps[~synthName].copy;
	~synthArgMap.keys;
	//~synthArgMap[\lforate] = ControlSpec.new(minval: 0.25, maxval: 8, warp: 'exp');
	//~synthArgMap[\lfoamt] = ControlSpec.new(minval: 0.1, maxval: 1);
	~synthArgMap[\gain] = ControlSpec.new(minval: 0.1, maxval: 4.0, warp: 'exp');
	//~synthArgMap.remove[\pitch];//why this no work?
	~synthArgMap[\pitch] = nil;
	~synthArgMap[\windowSize] = ControlSpec.new(minval: 64.reciprocal, maxval: 2, warp: 'exp');
	//~synthArgMap[\lfoamt] = ControlSpec.new(minval: 0.1, maxval: 1);
	~factory = PSSynthDefPhenotypeFactory.new(
		synthDef: ~synthName,
		synthArgMap: ~synthArgMap);
	//Weirdly, this seems to work best if the fitnessPollRate is lower than the
	//update rate.
	~control = PSCompareSynthController.new(
		numChannels:2,
		log:~log,
		leakCoef:0.5,
		maxPop:population,
	);
	~control.extraSynthArgs = [\lagtime, 0.2, \buffer, ~buffers[0], \pan, {1.0.rand2}];
	~control.leakCoef = 0.05;
	//~control.listenSynthDef = \ps_judge_pitchamp_distance__1_1;
	//~control.listenSynthDef = \ps_judge_pitch_distance__1_1;
	//~control.listenSynthDef = \ps_judge_fft_distance_wide__1_1;
	//~control.listenSynthDef = \ps_judge_fft_distance_narrow__1_1;
	//~control.listenSynthDef = \ps_judge_convolution__1_1;
	//~control.listenSynthDef = \ps_judge_cepstral_distance__1_1;
	//~control.listenSynthDef = \ps_judge_mfcc_distance__1_1;
	~control.listenSynthDef = \ps_judge_mfcc_distance_amp__2_1;
	~control.play(~phenogroup, outbus: ~swarmOut, targetbus: ~targetbus);
	s.sync;
	1.wait;

	//now set up the "swarm" that will control their evolution
	~swarm = PSLocalOptimisingSwarm(
	//~swarm = PSOptimisingSwarm(
		(\populationSize: population,
		\initialChromosomeSize: ~synthArgMap.size,
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
	~net = NetAddr("127.0.0.1", 57131);
	~swarm.net_(~net);
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
~buffers[0].plot
//listen for a while.
//experiment
ServerTreeGui.makeWindow(s);
s.queryAllNodes;

//when you are bored, do a
~swarm.free;
~phenoGroup.free;
~targetbus.free;