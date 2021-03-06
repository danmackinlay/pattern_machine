/*
Wavvie
TODO:
1. Misc shit
* I really would like some modulateable indexes to the grains's synth params
* by the way, looks like Pfset or esp Pproto could clean up resource allocation. Later.
* ArrayWarp should extend mm's ArrayWarp (in Autogui) by subclassing and do two things:
  * allow exponential interpolation
  * accept a parameters indicating what proportion of the range should be interpolated and what quantized.
* detect note onsets for sequencing purposes, and index by onset
  * Coyote is from BatUgens, purely time-domain. Looks elegant, though I've had a couple of Batugens explode on me
  * Onsets is included in the distro, pure FFT, multiple methods
  * OnsetsDS is the Dan Stowell thingy; (circumstantially looks to be the prototype for Onsets)
  * PV_HainsworthFoote and PV_JensenAndersen are too.
  * SLOnset is a Nick Collins joint, so likely to be a little, uh, sporadic
* pitch recording
* some kind of better notion of what sampling a bar means
* cue (i.e. preview) scrubbing of sample buffer
* click track for recording sync
* manual tuning of transpositions
* create evolving long-lived sequences
* might make more sense to, instead of having different mixer channels, to mix at the pattern level for different samples.
* Audit for zipper noise
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

*/

ServerTreeGui.makeWindow(s);
Server.default = PS.serverboot.(\local, \builtin);
(
var samples,
	server,
	state;

server = Server.default;
state = (
	sampleDur: 60.0,
	server: server,
	inbus: server.inputBus.subBus(0,1),
	outbus: server.outputBus.subBus(0,2),
);

~state=state;
state.server.waitForBoot({
	var samplingstrip, samples, clock;
	clock = TempoClock(140/60);
	samples = this.executeFile(
		PS.scriptpath +/+ "wavvie_samples.scd").value(state);
	CmdPeriod.doOnce({ samples.free});
	this.executeFile(PS.scriptpath +/+ "wavvie_synths.scd").value(state);
	s.sync;
	samplingstrip = PSSamplingStrip.new(
		state:state, samples: samples,
		inbus: state.inbus, outbus:state.outbus,
		clock:clock);
	CmdPeriod.doOnce({ samplingstrip.free});

	state.make({
		~samplingstrip = samplingstrip;
		~samples = samples;
		s.sync;
		{samplingstrip.rec(10.0);}.defer(1.0);
		~lfo2del = 0.0;
		~lfomodamp = 1/2;
		~param = 1;
		~interval = 2;
		~buffers = ["a", "b", "c"];
	});

});
)
(
	var state = ~state, paramspace, controlchan, scheduletask, playfunc;
	state.paramspace = paramspace = PSParamSpace(\wavviebasic);
	paramspace.newParam(\lfomodf, PSLookupSpec([1/4,1/3,1/2,1,2,3,4,6]));
	paramspace.newParam(\lfobasef, PSLookupSpec([1/4,1/3,1/2,1,2,3,4,6]));
	paramspace.newParam(\lfomodamp, [0.001, 1.0, \exp]);
	paramspace.newParam(\lfo2amp, [-0.1, 0.1]);
	paramspace.newParam(\lfo2grain, [-0.1, 0.1]);
	paramspace.newParam(\lfo2pan, [-0.1, 0.1]);
	//paramspace.newParam(\lfo2del, [-0.00001, 0.00001, \tan]); //nah
	paramspace.newParam(\timeago, PSLookupSpec([1,2,3,4,8,12,16]));
	paramspace.newParam(\grainsize, PSLookupSpec([1,2,4,8,16,32]/32));
	paramspace.newParam(\pitchrate, PSLookupSpec([1/2,1,2]));
	paramspace.newParam(\combed, [0.001, 1.0,\exp]);
	paramspace.newParam(\pan, \pan);
	paramspace.newParam(\windowRandRatio, [0.0,1.0]);
	paramspace.newParam(\allpdelayratio, [0.1,1.0]);
	paramspace.newParam(\allpdecayratio, [1,8,\exp]);
	paramspace.newParam(\posrate, PSLookupSpec([-1,-1/2,-1/4,0,1/4,1/2,1]));
	//ignored
	//paramspace.newParam(\sustainDur, [0.25, 16]);
	state.controlchan = controlchan = PSHawkesLemurControlChan.new(
		trace:false, state: state);

	state.playfunc = playfunc = {
		//\playing.postcs;
		PHawkes.cluster(
		    nChildren: Ppoisson.newFromCluster(state.cluster),
			wait: 2.pow(Prand((-4..1),inf)),
			mark: Prand([-2,2],inf),
			accum:true,
			maxGen:12,
			exoEvent: (
				instrument: \ps_bufgrain_type_2__1x2,
				sendGate: false,
				lfophase: 0,
				db: -10.0,
				overlaps: 4,
				delta: 1,
				sustainDur: 2,
			)
		).trace.play(
			clock: state.clock,
			protoEvent: state.samplingstrip.baseEvent,
			quant:1
		);
	};
	scheduletask = Routine({
		var ctr=0;
		inf.do({
			ctr = (ctr + 1) % (state.interval);
			//[\ctr, ctr, thisThread.beats].postln;
			(ctr==0).if({
				playfunc.value;
			});
			1.yield;
		})
	}).play(state.clock, 1);
)

~state.samplingstrip.rec(1.0);
~state.samplingstrip.rec(60.0);
~state.samplingstrip.sourceBuf(3);
~state.samplingstrip.sourceBuf(\tuneful,4);
~state.samplingstrip.sourceBuf(\choral,1);
~state.samplingstrip.sourceBuf(\people,0);
~state.samplingstrip.sourceBuf(\siren,0);
~state.samplingstrip.sourceBuf(\desolation,0);
~state.samples.at(\tuneful, 2);
~state.interval=2
i.state;
i.intAddr;
OSCFunc.trace(false);
~state.postcs