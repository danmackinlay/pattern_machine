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
var state;
fork {
	state = this.executeFile(~pmscripts +/+ "apoca_setup.scd");
	s.sync;
	state.postcs;
	state.putAll((
		voices: Array.fill(4, List.new),
		bardelta: 4,
		seed: 1128,
		reseed: true,
		looping: 0,
		pan: 0.0,
		chaos: 0,
		trans: [1],
		voicestates: Array.fill(4, nil),
	));
	state[\voicestates][0] = Event.new(n:60, proto: ~state).putAll((
		parambus1: ~state.subBus(0),
		channel: ~state.voicechannels[0]
	));
	state.voices[0].add(
		this.executeFile(
			~pmscripts +/+ "apoca_inst.scd"
		).value(
			~state[\voicestates][0],
			0
		)
	);
	~state=state;
}
)
~state.voicestates[0][\trans]=[1/4,1,4/3];
~state.vox2state[\trans]=[1/4,1];
~state.vox3state[\trans]=[1,2];
~state.vox4state[\trans]=[1,4/3,2];

~killList.value(~state.voices[0]);
~killList.value(~state.vox2);
~killList.value(~state.vox3);
~killList.value(~state.vox4);

~killAll.value;

~state.reverb1.set(\wet,1);
~state.reverb2.set(\wet,1);
~state.reverb3.set(\wet,1);
~state.reverb4.set(\wet,1);

~state.metaparams;
~state.sourcesound.set(\bufnum,~sampsetbufdict[\tuneful][0]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\siren][0]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\desolation][0]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\choral][0]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\people][0]);

~state.sourcesound.set(\livefade, 0);
~state.sourcesound.set(\livefade, 1);
~state.mixingboard.free;

~sampsetpaths;
~sampsetbufdict;
~sampsetbufarray;

this.executeFile(~pmscripts +/+ "apoca_midi.scd").value(~state).do(~state.mididefs.add(_));
