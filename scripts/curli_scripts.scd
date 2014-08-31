/*
Curlicue

TODO: (priority order)
* decent Lemur template
* OSC triggering for:
  * loop re-ordering
  * gestures
* audio-input-driven effects
* granular choir
* tap sync
* enveloped gestures
* get rid of clicks by
  * restrict sample looping to first 30 seconds, OR
  * soundfile-length-sensitive sound playing OR
  * just edit the fucking files
* level meter
  * or listen on buses using Ndef, then JIT mixers
* stateful algorithm to navigate through with wiimote
*/
Server.default=s=Dan.serverboot(prox:\local, device:\rme);
Server.default=s=Dan.serverboot(prox:\local, device:\builtin);

~state.mixingboard.free
MixerChannel.freeAll;

(
var state = ();
~state=state;
fork {state.make({
	~server = s;

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

	//sample loading
	~samples = PSSamples.new(basePath: PS.scsamplepath);
	~samples.initFromDict((
		siren: [
			"22370__druidus__Civil_Defence_Siren.wav",
			"24347__fonogeno__Police_sirens-short.wav",
			"30476__LG__Dutch_air_raid_warning_02.wav",
			"43807__daveincamas__WW2AirplaneFlyover.wav",
		],
		people: [
			"actors-laughing.wav",
			"tortureguy-3.wav",
			"actors-siren.wav",
			"actors-tuning.wav",
		],
		desolation: [
			"varese_on_a_lathe.wav",
			"whistling-wind.wav",
			"seagull-walk.wav",
			"10334_batchku_burning_iceberg.aiff",
		],
		tuneful: [
			"Unknown_Lead_Vocal.wav",
			"NS-wind-chimes-002-denoise-edit.wav",
			"CONCERTOFORCLARINETP2-solo.wav",
			"uc-ezchord.wav",
		],
		// choral: [
		// 	"choir/namgyalmonastery-chanthighlight.wav",
		// 	"choir/magnificat-build.wav",
		// 	"choir/huunhuurtu-legend.wav",
		// 	"choir/bulgur-legend.wav",
		// ],
	));
	CmdPeriod.doOnce({ ~samples.free });
	s.sync;
	//~voices = Array.fill(4, List.new);
	//~voicestates = Array.fill(4, nil);
	~nextVoice = 0;
	~bardelta= 4;
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
	this.executeFile(PS.scriptpath +/+ "basic_mixer_setup.scd").value(state);
})};
)
(
var localstate, state = ~state, i = state.nextVoice;
fork {
	localstate = Event.new(n:60, proto: state);
	state[\voicestates][i] = localstate;
	state.voices[i].add(
		this.executeFile(
			PS.scriptpath +/+ "curli_inst.scd"
		).value(
			localstate,
			i
		)
	);
	state[\nextVoice] = i + 1;
};
)

(
var loc = ~state[\voicestates][~state[\nextVoice]-1];
loc.outchannel.play(loc.pat, (clock: loc.clock)).postcs;
)
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
~state.mixingboard.free;


	~state.sourcesounds = ~state.inputchannelstrips.collect({|strip| strip.play((
		instrument: \playbuf_soundin__1x1,
		//clocktempo: PContext(state, \tempo),
		in: ~extinbus,
		bufnum: ~defaultSourcebuf,
		livefade: 0.0,
		loop: 1,
		sendGate: false,//persist
	))});
