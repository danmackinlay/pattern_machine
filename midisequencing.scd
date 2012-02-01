MIDIClient.init; 
m = MIDIOut(0, MIDIClient.destinations.at(0).uid);

(
~noteflume = ();
~notes = [60, 65, 67];
~noteweights = [64, 64, 64];
~power = 1;
~midichunks = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midinote, Pfunc({~notes.choose}),
	\delta,  Pexprand(0.0625, 2, inf),
	\sustain, Pexprand(0.0625, 2, inf),
	\chan, 0,
	\amp, Pfunc({((1.pareto(~power).min(127))/127).postln;}),
	\midiout, m
).play;

~notes.putEach([0,1,2], [70, 75, 77]);
)
(
~midichunksoverlap = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midinote, Pfunc({~notes.choose}),
	\delta,  0.1,
	\sustain, 0.2,
	\chan, 0,
	\amp, Pexprand(1/127, 1, inf),
	\midiout, m
).play;
)