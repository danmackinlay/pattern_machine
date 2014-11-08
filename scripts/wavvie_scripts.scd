/*
Wavvie

TODO:
* might make more sense to, instead of having different mixer channels, to  mix at the pattern level for different samples.
* Audit for zipper noise
* switch from Event type Note to Grain, and avoid having to think about it. (Actually, SC throws a tantrum.)
* Spectrum is a little thick; inbuilt filtering would be nice
* switch between external (live, RME) and internal mixers
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

ServerTreeGui.makeWindow(s);
Server.default = Dan.serverboot(\local, \builtin);
(
var masterstrip, samples, server, state;
server = Server.default;
state = (
	sampleDur: 60.0,
	server: server,
	patthandles: List.new,
	inbus: server.inputBus.subBus(0,1),
	outbus: server.outputBus.subBus(0,2),
);
~state=state;
state.server.waitForBoot({
	var wavvie, samples, streamer;
	samples = this.executeFile(PS.scriptpath +/+ "wavvie_samples.scd").value(state);
	CmdPeriod.doOnce({ samples.free});
	this.executeFile(PS.scriptpath +/+ "wavvie_synths.scd").value(state);
	s.sync;
	wavvie = PSWavvie.new(state:state, samples: samples, inbus: state.inbus, outbus:state.outbus);
	CmdPeriod.doOnce({ wavvie.free});
	streamer = PSStreamer.new(
		state: state,
		//notecallback: {|ev, seq| [seq.clock.beats, ev, seq].postcs; ev;},
		//debug: true
	);
	//streamer.parentEvent_(Event.default.putAll(wavvie.baseEvent));
	streamer.play(
		//trace: true
	);
	CmdPeriod.doOnce({ streamer.free});

	state.make({
		~wavvie = wavvie;
		~samples = samples;
		~streamer = streamer;
		s.sync;
		{wavvie.rec(10.0);}.defer(1.0);
		~combed = 0.0;
		~lfobasefs = PSquama.lin([1,2,3,4,6]);
		~jumps = PSquama.lin([1,2,4,8]);
		~grains = PSquama.lin([1,2,4,8,16,32]/32);
		~transps = PSquama.lin([-1,-2,1,2]);
		~lfo2del = 0.0;
		~lfomodamp = 1/2;
		~windowRandRatio = 0.01;
	});

});
)
(
	~state.streamer.notecallback = #{|evt, state, streamer|
		evt.use({
			//evt.postcs;
			~lfobasefs = streamer.beat2freq(state.lfobasefs.choose);
			~lfomodf = streamer.beat2freq(state.lfobasefs.choose);
			~lfomodamp = state.lfomodamp;
			~lfophase = 0;
			~lfo2amp= -0.25;
			~lfo2grain = 0;
			~lfo2pan = 0.0;
			~lfo2del = state.lfo2del;
			~posrate = 0.125 * (0.5.coin*2 -1);
			~timeago = streamer.beat2sec(state.jumps.choose);
			~grainsize = streamer.beat2sec(state.grains.choose);
			~windowRandRatio = state.windowRandRatio;
			~sustainDur = streamer.beat2sec(2.pow((-2).rrand(4)));
			~db = -10.0;
			~pan = 0.8.rand2;
			~pitchrate = state.transps.choose;
			~overlaps = 4;
			~allpdelayratio = 0.173; //enharmonic sounds better
			~allpdecayratio = 4;
			~combed = state.combed;
			evt.postcs;
			//evt;
		});
		evt;
	};
	~state.patthandles.add(~state.streamer.add(
		(~state.wavvie.baseEvent.putAll((
			instrument: \ps_bufgrain_type_2__1x2,
			type: \note,
			dur: 1,
			sendGate: false,
		))).asPattern
	));
)
(
	~state.patthandles.add(~state.streamer.add((
		instrument: \default,
		type: \note,
		dur: 1,
	).asPattern));
)
~state.wavvie.rec(10.0);
~state.wavvie.baseEvent;
~state.wavvie.buf.query;
~state.wavvie.buf.updateInfo;
~state.wavvie.buf.plot;
~state.wavvie.buf.numFrames
~state.wavvie.buf.sampleRate
~state.wavvie.buf.numChannels
~state.wavvie.phasebus.get

~state.patthandles;
~state.streamer.removeAt(2);
~state.streamer.childStreams;
~state.streamer.stopChildren;
//~state.streamer.clock.tempo
//t=~state.streamer.add(Pbind(\degree, 1, \delta, 1), id: \a);

/*
TODO NOW:

1. create new short lived sequences based on current params
2. create evolving long-lived sequences
*/


~state.wavvie.id;
~state.streamer.parentEvent;
~state.streamer.stopChildren;
~state.wavvie.inbus;
~state.wavvie.bus;
~state.wavvie.outbus;

~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\tuneful,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\people,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\choral,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\siren,0));
~state.sourcesounds[0].set(\bufnum, ~state.samples.key(\desolation,0));
~state.samples.at(0);
~state.samples.key(\people,0);
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
(
n=PSNoteCallback((a:1), {
	arg evt, seq;
	~b = seq.state.a + 1;
});
)
Pattern
(
(degree: 1).asPattern.trace.play(protoEvent: (b:1))
)