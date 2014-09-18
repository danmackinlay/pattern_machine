/*
Curlicue

TODO:
* decent Lemur template
* fix double reseed problem
* counts in seconds, not beats
* OSC triggering for:
  * overall
    * main input looping
    * gestures
    * seed value
    * tempo overall
    * attack and decay
  * per voice
    * offset
    * jump size
    * reseeding
    * looping
    * delay scaling
    * quantization
    * strength
    * density
    * level
    * reverb mix
    * chaos
    * transposition
* tap sync
* enveloped gestures
* get rid of clicks by
  * soundfile-length-sensitive sound playing OR
* master gain
* channel synth (limi, gain, level reporting, perhaps EQ?)
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
	~sourcesounds[0].set(\bufnum,~samples.key(\choral,0));

	~seed = 1128;
	~density = 1.0; //rate of impacts
	~intensity = 1.0; //expected polyphony
	~chaos = 0.0;
	~loopseed = true;
	~looping = 0;
	~bpm = 140;
	~amp = 0.5;
	~pan = 0.0;
	~trans = [1];
	~quantum = 1/4;
	~strength = 1.0;
	~controls = List.new;
	~attack = 0.1;
	~release = 0.3;
	~stationarity = 1.0;
	~debugSpawn = true;
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
var localstate, state = ~state, i = ~state.nextVoice, foo;
fork {
	localstate = Event.new(n:60, proto: state, know: true);
	localstate.make({
		~inbus = state.inbuses[0];
		~outbus = state.instbusallocator.alloc;
		~loopBeats = 4;
		~debugSpawn = false;
		~delscale = 1/4;
		~beatoffsets = [0,1,3,5];
	});
	state.nextVoice = i + 1;
	foo =  this.executeFile(PS.scriptpath +/+ "curli_inst.scd").value(localstate,i);
	[\foo, foo].postcs;
	s.sync;
	state.voiceStates[0].rec(30);
};
)
(
b=BusMeters.new(s, ~state.inbuses).start;
b.gui;
~state.inbuses[0].makeBusMeter
~state.voiceStates[0].loopin(0);
~state.voiceStates[0].loopin(1);
~state.voiceStates[0].debugSpawn=false;
~state.voiceStates[0].stationarity=0;
~state.voiceStates[0].stationarity=1.0;
~state.voiceStates[0].cleanup();
~state.voiceStates[0].rec();
~state.voiceStates[0].loopbuf.plot;
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