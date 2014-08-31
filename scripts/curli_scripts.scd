/*
Curlicue

TODO: (priority order)
* FUCK THIS HORRIBLE CONCURRENCY HELL
* decent Lemur template
* OSC triggering for:
  * loop re-ordering
  * gestures
* audio-input-driven effects
* granular choir
* tap sync
* enveloped gestures
* get rid of clicks by
  * restrict sample looping to first 30 seconds, OR
  * soundfile-length-sensitive sound playing OR
  * just edit the fucking files
* level meter
  * bareback, through "http://doc.sccode.org/Classes/LevelIndicator.html"
  * or listen on buses using Ndef, then JIT mixers
* stateful algorithm to navigate through with wiimote
* MIDI slider velocity
*/
(
~state = (a:1);
~str =Pbind(\delta, PContext(~state, \a)).trace.play;
)
//Server.default=s=Dan.serverboot(prox:\local, device:\rme);
Server.default=s=Dan.serverboot(prox:\local, device:\builtin);
(
var state = ();
~state=state;
fork {
	this.executeFile(PS.scriptpath +/+ "curli_setup.scd").value(state);
	state.putAll((
		voices: Array.fill(4, List.new),
		voicestates: Array.fill(4, nil),
		nextVoice: 0,
		bardelta: 4,
		seed: 1128,
		reseed: true,
		looping: 0,
		pan: 0.0,
		chaos: 0,
		trans: [1],
		lambda:2,
		quant:1/4,
		strength: 1,
		controls: List.new;
	));
}
)
(
var localstate, state = ~state, i = state.nextVoice;
fork {
	localstate = Event.new(n:60, proto: state);
	state[\voicestates][i] = localstate;
	state.voices[i].add(
		this.executeFile(
			PS.scriptpath +/+ "curli_inst.scd"
		).value(
			localstate,
			i
		)
	);
	state[\nextVoice] = i + 1;
};
)
~state[\voicestates][0].stream.postcs;
//worka
~state[\voicestates][1].pat.play;
//not works
(
var loc = ~state[\voicestates][~state[\nextVoice]-1];
loc.outchannel.play(loc.pat, (clock: loc.clock)).postcs;
)
~state.voicestates[0][\trans]=[1/4,1,4/3];
~state.voicestates[1][\trans]=[1/4,1];
~state.voicestates[2][\trans]=[1,2];
~state.voicestates[3][\trans]=[1,4/3,2];

~killList.value(~state.voices[0]);
~killList.value(~state.voices[1]);
~killList.value(~state.voices[2]);
~killList.value(~state.voices[3]);

~killAll.value;

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

