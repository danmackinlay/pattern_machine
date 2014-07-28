/*
Apocalypse

TODO: (priority order)
* MIDI/wii triggering for:
  * looping
  * loop re-ordering
  * kill all synths (~killall.value;)
  * gestures
* markov models with reseedable seed (see MarkovSet)
* audio-input-driven effects
* granular choir
* tap sync
* enveloped gestures
* restrict sample looping to first 30 seconds, OR
* soundfile-length-sensitive sound playing OR
* put fade-outs in sound files
* toggle feedback lights on midi keyboard
* level meter
* stateful algorithm to navigate through with wiimote
* instead of explicitly accessing "state" all the time, I should execute all the code inside the Environment, then pop off and pass it around.
* MIDI slider velocity
* automatic param control bus numbering
*/
//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\builtin);
(
var state = ();
~state=state;
fork {
	this.executeFile(~pmscripts +/+ "apoca_setup.scd").value(state);
	state.putAll((
		voices: Array.fill(4, List.new),
		voicestates: Array.fill(4, nil),
		bardelta: 4,
		seed: 1128,
		reseed: true,
		looping: 0,
		pan: 0.0,
		chaos: 0,
		trans: [1],
	));
}
)
~state.postcs;
(
var localstate, state = ~state;
fork {
	localstate = Event.new(n:60, proto: state).putAll((
		parambus1: state.parambuses.subBus(0),
		channel: state.voicechannels[0],
		phasebus: state.loopphasebuses.subBus(0),
		fuck: \you,
	));
	localstate.postcs;
	state[\voicestates][0] = localstate;
	state.voices[0].add(
		this.executeFile(
			~pmscripts +/+ "apoca_inst.scd"
		).value(
			state[\voicestates][0],
			0
		)
	);
};
)
~state.loopphasebuses.subBus(0).asMap;
~state[\voicestates][0].postcs;
~state[\voicestates][0][\phasebus]=~state.loopphasebuses.subBus(0);
.postcs;
~state.voicestates[0][\trans]=[1/4,1,4/3];
~state.voicestates[1][\trans]=[1/4,1];
~state.voicestates[2][\trans]=[1,2];
~state.voicestates[3][\trans]=[1,4/3,2];

~killList.value(~state.voices[0]);
~killList.value(~state.voices[1]);
~killList.value(~state.voices[2]);
~killList.value(~state.voices[3]);

~killAll.value;

~state.reverbs[0].set(\wet,1);
~state.reverbs[1].set(\wet,1);
~state.reverbs[2].set(\wet,1);
~state.reverbs[3].set(\wet,1);

~state.metaparams;
~state.sourcesound.set(\bufnum,~state.sampsetbufdict[\tuneful][0]);
~state.sourcesound.set(\bufnum,~state.sampsetbufdict[\siren][0]);
~state.sourcesound.set(\bufnum,~state.sampsetbufdict[\desolation][0]);
~state.sourcesound.set(\bufnum,~state.sampsetbufdict[\choral][0]);
~state.sourcesound.set(\bufnum,~state.sampsetbufdict[\people][0]);

~state.sourcesound.set(\livefade, 0);
~state.sourcesound.set(\livefade, 1);
~state.mixingboard.free;

~state.sampsetpaths;
~state.sampsetbufdict;
~state.sampsetbufarray;

