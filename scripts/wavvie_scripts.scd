/*
Wavvie

TODO:
* might make more sense to, instead of having different mixer channels, to  mix at the pattern level for differnt samples?
* Audit for zipper noise
* switch from Event type Note to Grain, and avoid having to think about it. (Actually, SC throws a tantrum.)
* Spectrum is a little thick; inbuilt filtering would be nice
* off switch for all notes (external gate?)
* switch between external (live, RME) and internal mixers using a BusAllocator
* Multiple synths
* copula params?
* interesting param map

  * poss Martin Marier's excellent PresetInterpolator
  * Or Wekinator

* interesting rhythm somehow

  * so also a non-bar-oriented synth
  * FSM pattern
  * smart accent

* or bar oriented:

  * GUI is needed
  * decent Lemur template
   * or NexusUI

* pitch recording
* OSC triggering for:

  * overall
  * gestures

  * live in

    * sample source
    * tempo overall

      * tap sync?

  * per voice

    * overall "weirdness" param to control with trivial mapping
    * overall "intensity" param
    * I kinda feel we wan to control marginals and correlation of params
    * quantization
    * level
    * reverb mix?
    * attack/release
*/
(
var masterstrip, state = ();
~state=state;
state.server = ~server;
state.server.doWhenBooted({
	masterstrip = PSStrip.new(
		id: \wav,
		numChannels: 8,
		clock: TempoClock.new,
		state: state);
	CmdPeriod.doOnce({ masterstrip.free});
	state.make({
	~masterstrip = masterstrip;
	//sample loading
	~samples = masterstrip.freeable(PSSamples.new(basePath: PS.scsamplepath, dur: ~sampleDur));
	~samples.initFromDict((
		siren: [
			"22370__druidus__Civil_Defence_Siren.wav",
			"24347__fonogeno__Police_sirens-short.wav",
			//"30476__LG__Dutch_air_raid_warning_02.wav",
			"43807__daveincamas__WW2AirplaneFlyover.wav",
		],
		people: [
			"actors-laughing.wav",
			//"tortureguy-3.wav",
			"actors-siren.wav",
			"actors-tuning.wav",
		],
		desolation: [
			"varese_on_a_lathe.wav",
			//"whistling-wind.wav",
			//"seagull-walk.wav",
			"10334_batchku_burning_iceberg.aiff",
		],
		tuneful: [
			"Unknown_Lead_Vocal.wav",
			"NS-wind-chimes-002-denoise-edit.wav",
			"CONCERTOFORCLARINETP2-solo.wav",
			//"uc-ezchord.wav",
		],
		choral: [
			"angelite_legend_mmm.aif",
			"huunhuurtu_angelite_legend_build.wav",
			"namgyal.aif",
			"paert-Magnificat-climax.aif",
		],
	));
	s.sync;
	this.executeFile(PS.scriptpath +/+ "basic_mixer_setup.scd").value(strip);
	this.executeFile(PS.scriptpath +/+ "wavvie_synths.scd").value(state);
	s.sync;
	//sync fails to handle the source setting properly
	//~sourcesounds[0].set(\bufnum,~samples.key(\choral,0));
	{state.sourcesounds[0].set(\bufnum,state.samples.key(\tuneful,0))}.defer(1);
})});
)
(
var inst, sequencemaker = PSStreamer.new;
fork {
	inst = PSStrip.new(1, parent: masterstrip);
	localstate = inst.state;
	localstate.make({
		~inbus = state.inbuses[0];
		~outbus = state.instbusallocator.alloc;
		~controls = List.new;
		~seed = 1;
		~lfobasefs = PSquama.lin([1,2,3,4,6]);
		~jumps = PSquama.lin([1,2,4,8]);
		~grains = PSquama.lin([1,2,4,8,16,32]/32);
		~transps = PSquama.lin([-1,-2,1,2]);
		~lfo2del = 0.0;
		~lfomodamp = 1/2;
		~windowRandRatio = 0.01;
	});
	s.sync;

	localstate.use({
		sequencemaker = {
			(50.rand+10).collect({16.0.rand.round(0.25)}).sort;
		};
		seq = PSBarSeq(
			state: state,
			parentEvent: ~parentevt);
		seq.barcallback = {|seq|
			localstate[\seed].notNil.if({
				thisThread.randSeed_(localstate[\seed]);
			});
			seq.timePoints = sequencemaker.value;
		};
		seq.notecallback = {|evt, seq|
			localstate.use({
			//evt.postcs;
			evt[\lfobasefs] = beat2freq.(~lfobasefs.choose);
			evt[\lfomodf] = beat2freq.(~lfobasefs.choose);
			evt[\lfomodamp] = ~lfomodamp;
			evt[\lfophase] = 0;
			evt[\lfo2pos] = beat2sec.(0);
			evt[\lfo2amp]= -0.25;
			evt[\lfo2grain] = 0;
			evt[\lfo2pan] = 0.0;
			evt[\lfo2del] = ~lfo2del;
			evt[\posrate] = 0.125 * (0.5.coin*2 -1);
			evt[\timeago] = beat2sec.(~jumps.choose);
			evt[\grainsize] = beat2sec.(~grains.choose);
			evt[\windowRandRatio] = ~windowRandRatio;
			evt[\sustainDur] = beat2sec.(2.pow((-2).rrand(4)));
			evt[\db] = -10.0;
			evt[\pan] = 0.8.rand2;
			evt[\pitchrate] = ~transps.choose;
			evt[\overlaps] = 4;
			evt[\allpdelayratio] = 0.173; //enharmonic sounds better
			evt[\allpdecayratio] = 4;
			evt[\combed] = ~combed;
			//evt.postcs;
			});
		};
		~seq = seq;
		// ~stream = ~seq.play(clock: ~clock, trace:true);
		~stream = ~seq.play(clock: ~clock);
	});
	{inst.rec(10.0);}.defer(1.0);
};
)
~state.voiceStates[0].rec(10);
~state.voiceStates[0].seed=1;
~state.voiceStates[0].lfo2del=0.001;
~state.voiceStates[0].windowRandRatio=0.25;
~state.voiceStates[0].combed=0.5;
~state.voiceStates[0].seq.stream.randSeed;
~state.voiceStates[0].debugSpawn=false;
~state.bpm;
~state.bpm=120;
~state.updateTempo.();
~state.tempo;
~state.voiceStates[0].loopbuf.plot;

~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\tuneful,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\people,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\choral,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\siren,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\desolation,0));

~state.samples.at(0);
~state.samples.key(\people,0);
~state.voiceStates[0].parentevt[\group];
(
~spy = (
	instrument: \jack__1,
	in: ~state.inbuses[0],
	out: ~state.masteroutbus.subBus(0,1),
	group: ~state.outputgroup,
	server: ~state.server,
	addAction: \addToTail,
	sendGate: false,//persist
).play;
)
~spy.free;