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
* epic panning
* meditation bells
* extra chaosifier
* tap sync
* enveloped gestures
* timestretched escalating background accompaniment
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
*/

//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\builtin);

this.executeFile(~pmscripts +/+ "apoca_setup.scd");

this.executeFile(~pmscripts +/+ "apoca_1.scd");
this.executeFile(~pmscripts +/+ "apoca_2.scd");
this.executeFile(~pmscripts +/+ "apoca_3.scd");
this.executeFile(~pmscripts +/+ "apoca_4.scd");

~killList.value(~state.vox3);

~killAll.value;

~state.metaparams;
~state.sourcesound.set(\bufnum,~sampsetbufdict[\tuneful][3]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\siren][0]);
~state.sourcesound.set(\livefade, 0);
~state.sourcesound.set(\livefade, 1);
~state.mixingboard.free;

~sampsetpaths;
~sampsetbufdict;
~sampsetbufarray;