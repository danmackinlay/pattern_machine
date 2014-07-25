/*
Apocalypse

TODO: (priority order)
* MIDI/wii triggering for:
  * looping
  * loop re-ordering
  * kill all synths (~killall.value;)
  * triggering karin's gestures
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* markov models with reseedable seed (see MarkovSet)
* audio-input-driven effects
* granular choir
* change random seeds
* extra chaosifier
* tap sync
* enveloped gestures
* timestretched escalating background accompaniment
* meditation bells
* restrict sample looping to first 30 seconds, OR
* soundfile-length-sensitive sound playing OR
* put fade-outs in
* variable delay in front of allpass to make it more interesting
* midi keyboard toggle lights
* VU meter
* ticking clock sample
* control ableton with SC
* Jack routing into Live?
* Bulk sample loading based on MIR
* stateful algorithm to navigate through with wiimote
* instead of explicitly accessing "state" all the time, I should execute all the code inside the Environment, then pop off and pass it around.
* MIDI slider velocity
* remap to various RME outputs for hardware mixing (dammit, website down)
* go to 0-based indexing throughout
* automatic param control bus numbering
* hi pass
*/

Server.default=s=~serverboot.(prox:\local, device:\rme);
//Server.default=s=~serverboot.(prox:\local, device:\builtin);

this.executeFile(~pmscripts +/+ "apoca_setup.scd");
~state[\voices]= Array.fill(4, {List.new});
~state[\voicestates]= Array.fill(4, {Event.new(n:60, proto: ~state).putAll((
	bardelta: 4,
	seed: 1128,
	reseed: true,
	looping: 0,
	pan: 0.0,
	chaos: 0,
	trans: [1],
	))
});
~state.voices[0].add(
	this.executeFile(~pmscripts +/+ "apoca_inst.scd").value(
		~state[\voices][0].putAll((
			parambus1: ~state.subBus(i),
		)),
		0
	)
);

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
