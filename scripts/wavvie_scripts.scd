/*
Wavvie
TODO:
1. Misc shit
* by the way, looks like Pfset or esp Pproto could clean up resource allocation. Later.
* ArrayWarp should extend mm's ArrayWarp (in Autogui) by subclassing and do two things:
  * allow exponential interpolation
  * accept a parameters indicating what proportion of the range should be interpolated and what quantized.
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
*
2. Note timbre management
* consider adding a new EventType which has my requisite transforms in;
  In particular it could do certain perturbations in values depending on other parameters.
* interesting param map
  * poss Martin Marier's excellent PresetInterpolator in mmExtension
  * or Marje Baalman's predecessor, ParameterSpace in SenseWorld
  * Or Wekinator
  * Or multivariate logistic regression against different possible parameterisations to construct a basis set of axes.
    If we assumed monotonicity, this would be quite easy using, e.g. multiple linear regression.
    Or, random construction of a sparse basis, by e.g. random projection, which works for statisticians why not us?
    But I think this probably also requires a lot of work to make it sound comprehensible.
    NN gesture recogniser would actually be very nice, but I can't be arsed training such a net
* stereo movement within a note
* interesting perturbations
  * gaussian copula
  * linear addition
  * a fold transform, pref like some kind of pregresively wierder devils' staircase. maybe some kind of nicer map.
* fake decay
* I could make a param space and then search in similarity in a subset of dimensions. After all, I really only want to expand the variance in a few at a time
* create a meta-preset, giving whole ranges of parameters
* map a controller to various sub-ranges and quantisations and a correlator driven by markov states
* OR create many presets from these and Markov between them (or even assign them to the keyboard)
* some kind of clever designed parameterisation? Specify correlation prob?

3. Sequence management
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
* I could set up my kuramoto network (would even be natural on the server - could even multiplex the output of single synth into 24, or at least 16, subsynths)
* how do i get deterministic repetition?
* create a meta-preset, giving whole ranges of parameters
* how to control this shit?
* Baalman's ParameterSpace and Marier's PresetInterpolator are both very nice, but
  * ParameterSpace is too coupled to the 2d schtick
  * Marier's presumes highly specific binding logic and sorta wants you use Interpolator
  * both have lovely GUIs though, which is a serious plus if you had GUI programming as much as I do.
  * neither support general Hilbert space operations, which i think is essential.
  * to extend or rewrite?
  * PSParamSpace here we come

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
	//clean way to set non-OSC actions? right now have to comeback afterwards and add
	state[\timbralparams] = (
		combed: Parameter(name: "combed", value:0),
		octave: Parameter(name: "octave", value:0.5, spec: ControlSpec(-1,1,step:1)),
		timeago: Parameter(name: "timeago", value:0.0, spec: ControlSpec(1,32, step:1)),
	);
	state[\defaulttimbre] = Preset(
		params:state[\timbralparams].values,
		name: "DefaultTimbre");
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
~state.samplingstrip.sourceBuf(\choral,1);
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
ArrayWarp.new([0,1], [1,1,4]).makeWindow
Warp.warps
c=ControlSpec.new(0.5,2);
c.warp=ArrayWarp(c, [1,3,5]);
c.map(0.7)