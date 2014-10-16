/*
Wavvie

TODO:
* switch from Event type Note to Grain, and avoid having to think about it
* Spectrum is a little thick; inbuilt filtering would be nice
* GUI is needed
* off switch for all notes (external gate?)
* cleanup is not working great- fails to allocate bus correctly.
* switch between external (live, RME) and internal mixers using a BusAllocator
* tidier sample source selector
* interesting param map
* interesting rhythmn somehow
* random volume
* smart accent
* decent Lemur template
* or NexusUI
* OSC triggering for:

  * overall
  * gestures

  * live in

    * sample source
    * tempo overall

      * tap sync?

  * per voice

    * overall "weirdness" param to control with trivial mapping
    * buffer offset
    * stationarity
    * seed value
    * looping
    * quantization
    * strength
    * density
    * intensity
    * level
    * pan
    * reverb mix
    * transposition
    * reverb mix?
    * loop beats?
    * transposition
    * envelope "attackiness"?
    * modulation
    * reverb mix?

* master gain
* monitor channel
*/

(
var state = ();
~state=state;
state.server = ~server;

state.server.doWhenBooted({state.make({
	~ninputs = 1;
	~ninsts = 4;
	~sampleDur = 60;
	~bpm = 80;
	~clock = TempoClock.new(~bpm/60.0);

	//sample loading
	~samples = PSSamples.new(basePath: PS.scsamplepath, dur: ~sampleDur);
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
	CmdPeriod.doOnce({ state.samples.free });
	s.sync;
	this.executeFile(PS.scriptpath +/+ "basic_mixer_setup.scd").value(state);
	this.executeFile(PS.scriptpath +/+ "wavvie_synths.scd").value(state);
	s.sync;
	//sync fails to handle the source setting properly
	//~sourcesounds[0].set(\bufnum,~samples.key(\choral,0));
	{state.sourcesounds[0].set(\bufnum,state.samples.key(\choral,0))}.defer(1);
})});
)
(
var sequencemaker, seq;
var localstate, state = ~state, i = 0, foo;
fork {
	localstate = Event.new(n:60, proto: state, know: true);
	localstate.make({
		~inbus = state.inbuses[0];
		~outbus = state.instbusallocator.alloc;
		~controls = List.new;
	});
	foo =  this.executeFile(PS.scriptpath +/+ "wavvie_inst.scd").value(localstate, i);
	//[\foo, foo].postcs;
	s.sync;
	localstate.use({
		sequencemaker = {
			20.collect({32.0.rand.round(0.25)}).sort;
		};
		seq = PSWavvieSeq(
			state: state,
			parentEvent: ~parentevt);
		seq.barcallback = {|seq|
			seq.timePoints = sequencemaker.value.postcs;
		};
		seq.notecallback = {|evt, seq|
			evt[\posrate]=0.1;
			evt[\timeago]=1.0; // in seconds
			evt[\grainsize]=0.15.rand + 0.05; //in seconds
			evt[\windowRandRatio]=0.2.rand;
			evt[\sustainDur] = 4.0.rand+1; //inseconds
			evt[\db] = -10.0;
			evt[\pitchrate] = 1;
			evt[\overlaps] = 4;
			evt.postcs;
		};
		~seq = seq;
		~stream = ~seq.play(clock: ~clock);
	});
	{localstate.rec();}.defer(0.1);
};
)
//~state.voiceStates[0].rec(30);
~state.voiceStates[0].rec();
~state.voiceStates[0]
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

~state.sourcesounds[0].set(\livefade, 0);
~state.sourcesounds[0].set(\livefade, 1);

(\a: 5).gui;
~state.limiter.gui;
~state.sourcesounds[0];

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