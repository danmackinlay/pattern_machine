/*
Curlicue

TODO: (priority order)
* decent Lemur template
* OSC triggering for:
  * overall
    * main input looping
    * gestures
    * seed value
    * tempo overall
    * attack and decay
  * per voice
    * reseeding
    * looping
    * delay scaling
    * offset
    * density
    * level
    * reverb mix
    * chaos
* tap sync
* enveloped gestures
* get rid of clicks by
  * restrict sample looping to first 30 seconds, OR
  * soundfile-length-sensitive sound playing OR
  * just edit the fucking files
* level meter
  * or listen on buses using Ndef, then JIT mixers
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

	~seed = 1128;
	~density = 1;
	~chaos = 0;
	~reseed = true;
	~looping = 0;
	~pan = 0.0;
	~chaos = 0;
	~trans = [1];
	~lambda = 2;
	~quant = 1/4;
	~strength = 1;
	~controls = List.new;
	~attack = 0.1;
	~release = 0.3;

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
var localstate, state = ~state, i = ~state.nextVoice;
fork {
	localstate = Event.new(n:60, proto: state);
	localstate.make({
		~inbus = state.inbuses[0];
		~outbus = state.instbusallocator.alloc;
	});
	state.nextVoice = i + 1;
	this.executeFile(PS.scriptpath +/+ "curli_inst.scd").value(localstate,i);
};
)
(
~state.bpm;
~state.bpm=120;
~state.updateTempo.();
~state.tempo;
~state.attack=0.1;
)


~state.reseed=true;
~state.loop=true;
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

~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\tuneful,0));

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
~state.sourcesounds[0]