//This one is trying to be a breakbeat guy.
(
//init
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
//m.latency=0;

~pm = MIDIPercMap;
~clock=TempoClock.new(136/60);
~amen_break = Ppar([
	Pser([Pobind(\midinote, ~pm.ride_cymbal_1, \dur, 1/2, \amp, 1/2)],8),
	Pbind(
		\midinote, Pseq(~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(3) ++ ~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(3)),
		\dur, Pseq([1/2, 1/2, 3/4, 1/2, 1/4, 1/4, 1/4, 3/4, 1/4])
	)
]);
)
(
~patt=Ptrace(~amen_break <> (amp: 1, type: \midi, midiout: m, \chan: 9));
~patt.play(~clock);
)
(
var ps;
~logger = PostLogger.new();
ps = PSProductionSystem(~logger);
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, POp(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, POp(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, POp(\stretch, Affine1(3)));
ps.putOp(\truncToBar, Ppop(Pfindur(4, _)));
ps.putAtom(\amen_break, ~amen_break);
ps.putAtom(\onebeatrest, PoRest(1));
ps.putRule(\timetransform,
	PSChoice(
		2, [\doubleSpeed],
		1, [\halfSpeed],
		2, [\tripleSpeed],
		1, [\thirdSpeed],
	)
);
ps.putRule(\cut, \timetransform, \amen_break);
ps.putRule(\bar, \truncToBar, PSStarN(4,\cut));
ps.putRule(\root, PSStarN(4, \bar));
~ps=ps;
//~patt=Ptrace(ps.root);
~patt=ps.root;
~logger.minPriority = 2;
~patt=Ptrace(ps.root <> (amp: 1, type: \midi, midiout: m, \chan: 9));
~patt.play(~clock);
)
~logger.minPriority=0;
