/*
Wavvie

TODO:
* might make more sense to, instead of having different mixer channels, to  mix at the pattern level for differnt samples?
* Audit for zipper noise
* switch from Event type Note to Grain, and avoid having to think about it. (Actually, SC throws a tantrum.)
* Spectrum is a little thick; inbuilt filtering would be nice
* off switch for all notes (external gate?)
* switch between external (live, RME) and internal mixers using a BusAllocator
* Multiple synths
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
)
(
	~state.streamer.add((
		instrument: \ps_bufgrain_type_2__1x2,
		type: \note,
		dur: 1,
		sendGate: false,
	).asPattern);

	~state.streamer.notecallback = {|evt, state, streamer|
		state.use({
			//evt.postcs;
			evt[\lfobasefs] = streamer.beat2freq(~lfobasefs.choose);
			evt[\lfomodf] = streamer.beat2freq(~lfobasefs.choose);
			evt[\lfomodamp] = ~lfomodamp;
			evt[\lfophase] = 0;
			evt[\lfo2amp]= -0.25;
			evt[\lfo2grain] = 0;
			evt[\lfo2pan] = 0.0;
			evt[\lfo2del] = ~lfo2del;
			evt[\posrate] = 0.125 * (0.5.coin*2 -1);
			evt[\timeago] = streamer.beat2sec(~jumps.choose);
			evt[\grainsize] = streamer.beat2sec(~grains.choose);
			evt[\windowRandRatio] = ~windowRandRatio;
			evt[\sustainDur] = streamer.beat2sec(2.pow((-2).rrand(4)));
			evt[\db] = -10.0;
			evt[\pan] = 0.8.rand2;
			evt[\pitchrate] = ~transps.choose;
			evt[\overlaps] = 4;
			evt[\allpdelayratio] = 0.173; //enharmonic sounds better
			evt[\allpdecayratio] = 4;
			evt[\combed] = ~combed;
			//evt.postcs;
			evt;
		});
		[\AAAAAA, evt.asCompileString[..30], ].postcs;
		[\parent, evt.parent.asCompileString[..30]].postcs;
		[\legato, evt.legato].postcs;
		[\sustain, evt.sustain].postcs;
		evt;
	};
)

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