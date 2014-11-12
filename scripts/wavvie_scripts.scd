/*
Wavvie

TODO:

* stereo movement in these damn synths
* use state only to hold new *spawning* parameters; then I can pass them in without fear
* detect note onsets for sequencing purposes, and index by onset
  * Coyote is from BatUgens, purely time-domain. Looks elegant, though I've had a couple of Batugens explode on me
  * Onsets is included in the distro, pure FFT, multiple methods
* OnsetsDS is the Dan Stowell thingy; (circumstantially looks to be the prototype for Onsets)
  * PV_HainsworthFoote and  PV_JensenAndersen are too.
  * SLOnset is a Nick Collins joint, so likely to be a little, uh, sporadic
* pitch recording
* some kind of better notion of what sampling a bar means
* cue scrubbing of sample buffer
* manual tuning of transpositions
* create pattern factories with dynamic scale lookup
* create new short lived sequences based on current params
* create evolving long-lived sequences
* might make more sense to, instead of having different mixer channels, to mix at the pattern level for different samples.
* Audit for zipper noise
* switch from Event type Note to Grain, and avoid having to think about it. (Actually, SC throws a tantrum.)
* Spectrum is a little thick; inbuilt filtering would be nice
* switch between external (live, RME) and internal mixers
* interesting rhythm somehow
  * so also a non-bar-oriented synth
  * FSM pattern
  * smart accent
* or bar oriented:
  * GUI is needed
  * decent Lemur template
   * or NexusUI
* interesting param map
  * poss Martin Marier's excellent PresetInterpolator
  * Or Wekinator
*/

ServerTreeGui.makeWindow(s);
Server.default = Dan.serverboot(\local, \builtin);
(
var masterstrip, samples, server, state;
server = Server.default;
state = (
	sampleDur: 60.0,
	server: server,
	inbus: server.inputBus.subBus(0,1),
	outbus: server.outputBus.subBus(0,2),
);
~state=state;
state.server.waitForBoot({
	var samplingstrip, samples, streamer;
	samples = this.executeFile(PS.scriptpath +/+ "wavvie_samples.scd").value(state);
	CmdPeriod.doOnce({ samples.free});
	this.executeFile(PS.scriptpath +/+ "wavvie_synths.scd").value(state);
	s.sync;
	samplingstrip = PSSamplingStrip.new(state:state, samples: samples, inbus: state.inbus, outbus:state.outbus);
	CmdPeriod.doOnce({ samplingstrip.free});
	streamer = PSStreamer.new(
		state: state,
	);
	//streamer.parentEvent_(Event.default.putAll(samplingstrip.baseEvent));
	streamer.play(
		//trace: true
	);
	CmdPeriod.doOnce({ streamer.free});

	state.make({
		~samplingstrip = samplingstrip;
		~samples = samples;
		~streamer = streamer;
		s.sync;
		{samplingstrip.rec(10.0);}.defer(1.0);
		~combed = 0.0;
		~lfobasefs = [1,2,3,4,6];
		~jumps = [1,2,4,8];
		~grains = [1,2,4,8,16,32]/32;
		~transps = [-1,-2,1,2];
		~lfo2del = 0.0;
		~lfomodamp = 1/2;
		~windowRandRatio = 0.01;
		~param = 1;
	});
	state.streamer.notecallback = #{|evt, state, streamer|
		evt.use({
			//nothing ATM
		});
		evt.postcs;
		evt;
	};
});
)
(
	var state = ~state;
	~state.streamer.add(
		~state.samplingstrip.basePattern <> Pbind(
			\instrument, \ps_bufgrain_type_2__1x2,
			\type, \note,
			\sendGate, false,
			\degree, PGeomN(0, 0.8),
			\lfobasef, Prand(state.lfobasefs, inf),
			\lfomodf, Prand(state.lfobasefs, inf),
			\lfomodamp, state.lfomodamp,
			\lfophase, 0,
			\lfo2amp, -0.25,
			\lfo2grain, 0,
			\lfo2pan, 0.0,
			\lfo2del, state.lfo2del,
			\posrate, 0.125 * (0.5.coin*2 -1),
			\timeago, Prand(state.jumps, inf),
			\grainsize, Prand(state.grains, inf),
			\windowRandRatio, state.windowRandRatio,
			\sustainDur, Pfunc({2.pow((-2).rrand(4))}),
			\db, -10.0,
			\pan, 0.8.rand2,
			\pitchrate, Prand(state.transps, inf),
			\overlaps, 4,
			\allpdelayratio, 0.173,  //enharmonic sounds better
			\allpdecayratio, 4,
			\combed, state.combed,
		)
	);
)
5.exprand
~state.samplingstrip.rec(1.0);
~state.samplingstrip.rec(10.0);
~state.samplingstrip.sourceBuf(3);
~state.samplingstrip.sourceBuf(\tuneful,2);
~state.samplingstrip.sourceBuf(\choral,0);
~state.samplingstrip.sourceBuf(\people,0);
~state.samplingstrip.sourceBuf(\siren,0);
~state.samplingstrip.sourceBuf(\desolation,0);
~state.streamer.removeAt(2);
~state.streamer.stopChildren;
~state.samples.at(\tuneful, 2);
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

