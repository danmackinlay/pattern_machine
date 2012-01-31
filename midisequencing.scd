MIDIClient.init; 
m = MIDIOut(0, MIDIClient.destinations.at(0).uid);

(
p = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midinote, Pfunc({[64, 68, 69, 71].choose}),
	\delta,  Pexprand(0.0625, 2, inf),
	\sustain, Pexprand(0.0625, 2, inf),
	\chan, 0,
	\amp, Pexprand(1/127, 1, inf),
	\midiout, m
).play;
)