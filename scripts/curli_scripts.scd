/*
Curlicue

TODO:
* echette-style allpass delays (intensity is product of total length and amplitude)
* choose echette length algorithmically too
* cleanup is not working great- fails to allocate bus correctly.
* choose durations after quantization
* switch between external (live, MRE) and internal mixers
* tidier sample source selector
* transpose, jump etc fn (scaled list selector)
* interesting param map
* interesting rhythmn somehow
* random volume
* smart accent
* decent Lemur template
* OSC triggering for:
  * overall
    * gestures
    * live in
    * sample source
    * tempo overall
      * tap sync?
    * gestures?
  * per voice
    * overall "weirdness" param to control with trivial mapping
    * buffer offset
    * stationarity
    * inner envelope
    * outer envelope
    * minijump sizes
    * seed value (eventually, ALWAYS reseed and
      choose whether to stick to latest seed)
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
* get rid of clicks by
  * soundfile-length-sensitive sound playing
  * shifting record pointer
* record "past" - loop what JUST HAPPENED
* master gain
* channel synth (limi, gain, level reporting, perhaps EQ?)
* buffer emptying command
*/

//~server = Dan.serverboot(prox:\local, device:\rme);
//~server = Dan.serverboot(prox:\local, device:\motu);
~server = Dan.serverboot(prox:\local, device:\builtin);
(
var state = ();
~state=state;
state.server = ~server ?? {
	//Dan.serverboot(prox:\local, device:\rme);
	//Dan.serverboot(prox:\local, device:\motu);
	Dan.serverboot(prox:\local, device:\builtin);
};
~server = state.server;

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
	s.sync;
	//sync fails to handle the source setting properly
	//~sourcesounds[0].set(\bufnum,~samples.key(\choral,0));
	{state.sourcesounds[0].set(\bufnum,state.samples.key(\choral,0))}.defer(1);

	//default values for sub voices
	//cannot fall back to parent for these; local controls might be installed
	~modelvoice = Event.make({
		~debugSpawn = false;
		// * record
		// * minijump sizes
		~delquantumset = [1/4, 1/2, 1];
		~delquantumvar = 0.5; // MODULATE ME
		~deljumpset = [0,1,3,5];
		~deljumpvar = 0.5; // MODULATE ME
		// * overall "weirdness" param to control with trivial mapping
		~delscale = 0.5; // MODULATE ME
		// * stationarity
		~stationarity = 1.0; // MODULATE ME
		// * seed value
		~seed = 1;
		// * looping
		~loopseed = true;
		// * quantization
		~quantumset = [1/8, 1/4, 1/3, 1/2, 2/3, 1, 2, 4];
		~quantumparam = 0.0;  // MODULATE ME
		// * strength
		~strength = 0.0;  // MODULATE ME
		// * density
		~density = 8.0;  // MODULATE ME
		// * intensity
		~intensity = 3.0;  // MODULATE ME
		// * level (db might be nicer)
		~db = -6;  // MODULATE ME
		// * pan
		~pan = 0.0;  // MODULATE ME
		// * transposition
		~transset = [1, 3/2, 1/2, 2/3, 5/4 ];
		~transvar = 0.2;  // MODULATE ME
		// * envelope "attackiness"
		~attack = 0.05;
		~release = 0.4;
		~decay = 0.3;
		~sustainLevel = 0.5;
		// * modulation
		// * loop beats?
		~loopBeats = 4;
		// * reverb mix?
	});
	//UI interaction stuff
	// ~metaparamMap = PSMetaParamMap.new(inDims:3, outDims:10);
	// {metaparamMap.plot;}.defer;
	// CmdPeriod.doOnce({ ~metaparamMap.free });
	// ~paramUpdater = PSParamForwarder(metaparamMap, 0.05);
	// CmdPeriod.doOnce({ ~paramUpdater.free });
	// this.executeFile(PS.scriptpath +/+ "curli_wii.scd").value(state);
	// //to disable:
	//
	// CmdPeriod.doOnce({ OSCdef(\wii).free });
})});
)
(
var localstate, state = ~state, i = 0, foo;
fork {
	localstate = Event.new(n:60, proto: state, know: true);
	localstate.putAll(state.modelvoice);
	localstate.make({
		~inbus = state.inbuses[0];
		~outbus = state.instbusallocator.alloc;
		~controls = List.new;
		~strength = 1.0;
		//~debugSpawn = true;
	});
	foo =  this.executeFile(PS.scriptpath +/+ "curli_inst.scd").value(localstate, i);
	[\foo, foo].postcs;
	s.sync;
	//{state.voiceStates[i].rec();}.defer(0.1);
};
)
(
//~state.voiceStates[0].rec(30);
~state.voiceStates[0].rec();
~state.inbuses[0].makeBusMeter;
~state.voiceStates[0].loopin(0);
~state.voiceStates[0].loopin(1);
~state.voiceStates[0].debugSpawn=false;
~state.voiceStates[0].stationarity=0;
~state.voiceStates[0].stationarity=1.0;
~state.voiceStates[0].cleanup();
~state.voiceStates[0].loopbuf.plot;
~state.voiceStates[0].density=20;
~state.voiceStates[0].strength=0.0;
~state.voiceStates[0].strength=1.0;
~state.voiceStates[0].loopphasebus.get;
~state.bpm;
~state.bpm=120;
~state.updateTempo.();
~state.tempo;
~state.attack=0.1;
~state.stationarity=0;
~state.intensity=3;
~state.density=5.reciprocal;
~state.density=5;
~state.intensity=4;
~state.density=4;

~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\tuneful,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\people,0));
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\choral,0));

~state.voicestates[0][\trans]=[1/4,1,4/3];
~state.voicestates[1][\trans]=[1/4,1];
~state.voicestates[2][\trans]=[1,2];
~state.voicestates[3][\trans]=[1,4/3,2];

~state.metaparams;
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\tuneful,0));
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\siren,0));
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\desolation,0));
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\choral,0));
~state.sourcesounds[0].set(\bufnum,~state.samples.key(\people,0));


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