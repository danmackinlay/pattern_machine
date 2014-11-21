/*
Wavvie
TODO:
* create pattern factories with dynamic scale lookup
* by the way, looks like Pfset or esp Pproto could clean up resource allocation. Later.
* interesting rhythm. Just partition the bar somehow? give notes some kind of flaky releveance to their successors?
  * i kind of want to learn (from data), and then reproduce, my stochastic autocorrelation structure. Is that tenable with enveloped recurrence time and midi and such? I think so. maybe even with a dissonance kernel. It's not very much different than constructing a sequence with the specified spectrum. Obvious question: is there an inverse autocorrelative transform?
    Model: chord choices are i.i.d given the recurrence, or autocorrelation, structure.
* bar-free
  * smart accent
* or bar oriented:
  * GUI is needed
  * decent Lemur template
   * or NexusUI
* fucksake, let's just make some markov interval selections, k?
* or record a library midi patterns from my keyboard even
* interesting param map
  * poss Martin Marier's excellent PresetInterpolator in mmExtension
  * or Marje Baalman's predecessor, ParameterSpace in SenseWorld
  * Or Wekinator
  * Or multivariate logistic regression against different possible parameterisations to construct a basis set of axes.
    If we assumed monotonicity, this would be quite easy using, e.g. multiple linear regression.
    Or, random construction of a sparse basis, by e.g. random projection, which work for statisticians why not us?
    But I think this probably also requires a lot of work to make it sound comprehensible.
    NN gesture recogniser woudl actually be very nice, but I can't be arse training such a net

* ArrayWarp should extend mm's Array warp (in Autogui) by subclassing and do two things:
  * allow exponential interpolation
  * accept a parameters indicating what proprotion of the range should be interpolated and what quantized.
* stereo movement within a note
* fake decay
* detect note onsets for sequencing purposes, and index by onset
  * Coyote is from BatUgens, purely time-domain. Looks elegant, though I've had a couple of Batugens explode on me
  * Onsets is included in the distro, pure FFT, multiple methods
  * OnsetsDS is the Dan Stowell thingy; (circumstantially looks to be the prototype for Onsets)
  * PV_HainsworthFoote and  PV_JensenAndersen are too.
  * SLOnset is a Nick Collins joint, so likely to be a little, uh, sporadic
* pitch recording
* some kind of better notion of what sampling a bar means
* cue (i.e. preview) scrubbing of sample buffer
* click track for recording sync
* manual tuning of transpositions
* create evolving long-lived sequences
* might make more sense to, instead of having different mixer channels, to mix at the pattern level for different samples.
* Audit for zipper noise
* switch from Event type Note to Grain, and avoid having to think about it. (Actually, SC throws a tantrum.)
* Spectrum is a little thick; inbuilt filtering would be nice
* switch between external (live, RME) and internal mixers
* visualisation; something minimal.
  * if server synths, straight SendReply
    * but needs reverse mapping (boring)
* but could also have some light spectral analysis built in (3 band?)
  * generically, .collect on a pattern
    * but for live notes needs understanding of EventStreamCleanup, which looks grim
* I could slowly, live, learn the relationship between different sample params and dissonance in SC3
* I could set up my kuramoto network (would even be natural on the server - could even multiplex the output of ainsgle synth into 24, or at least 16, subsynths)
* how do i get deterministic repetition?
* I could make a param space and then search in similarity in a subset of dimensions. AFter all, I really only want to expand the variance in a few at a time
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
		~jumps = [1,2,3,4,8];
		~grains = [1,2,4,8,16,32]/32;
		~deltas = [1,2,4,8]/8;
		~transps = [1/2,1,2];
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
	state.streamer.tickcallback = #{|time, state, streamer|
		[\localtime, time].postcs;
	};

});
)
// how to manage these complicated events factories? via PresetInterpolator?
// but a lot of the stuff is not interpolable, e.g. diff numbers of markov states
// perhaps can interpolate just the cont values?
// Or markov action can jump over such values?
// but we would like several qualitatively different notes types
// and how to make live?
// stutter-edit style one-preset-per-note stuff?
// But where then the live state lookup business
// random perturbation?
/*

Summary: control via
1) midi triggering of evolved notes
2) half-preset interpolated params
3) some kind of clever designed parameterisation? Specify correlation prob?
*/

(
	var state = ~state;
	~state.streamer.add(
		~state.samplingstrip.basePattern <> Pbind(
			\instrument, \ps_bufgrain_type_2__1x2,
			\type, \note,
			\sendGate, false,
			\degree, PGeomN(0, 0.95), //hack to terminate after random time
			\lfobasef, Prand(state.lfobasefs, inf),
			\lfomodf, Prand(state.lfobasefs, inf),
			\lfomodamp, state.lfomodamp,
			\lfophase, 0,
			\lfo2amp, -0.25,
			\lfo2grain, 0,
			\lfo2pan, 0.0,
			\lfo2del, state.lfo2del,
			\posrate, 0.125 * (0.5.coin*2 -1),
			\timeago, PMarkovChain.random(
				disorder:0.2,
				ordertype: \static,
				expressions: state.jumps),
			\delta, PMarkovChain.random(
				disorder:0.5,
				ordertype: \static,
				expressions: state.deltas),
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
~state.samplingstrip.rec(1.0);
~state.samplingstrip.rec(60.0);
~state.samplingstrip.sourceBuf(3);
~state.samplingstrip.sourceBuf(\tuneful,4);
~state.samplingstrip.sourceBuf(\choral,0);
~state.samplingstrip.sourceBuf(\people,0);
~state.samplingstrip.sourceBuf(\siren,0);
~state.samplingstrip.sourceBuf(\desolation,0);
~state.streamer.removeAt(2);
~state.streamer.stopChildren;
~state.samples.at(\tuneful, 2);
~state.jumps=[1,4,8,10,12,16];
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
 