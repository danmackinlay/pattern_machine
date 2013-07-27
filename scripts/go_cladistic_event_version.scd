//This one is trying to be a breakbeat guy.
//NB - am not sure that the \truncatetobar operator is behaving from within the pattern. should test.
(
//init
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
//m.latency=0;
m.noteOn(0,36,127);
//~pm = GeneralMIDIPercMap;
~pm = MicrotonicMIDIPercMap;
~amen_break = Ppar([
	Pser([Pobind(\midinote, ~pm.ride_cymbal_1, \dur, 1/2, \amp, 1/2)],8),
	Pbind(
		\midinote, Pseq(~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(3) ++ ~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(3)),
		\dur, Pseq([1/2, 1/2, 3/4, 1/2, 1/4, 1/4, 1/4, 3/4, 1/4])
	)
]);
)
(
~clock=TempoClock.new(136/60);
~patt=Ptrace(~amen_break <> (amp: 1, type: \midi, midiout: m, \chan: 9));
~patt.play(~clock);
)
(
var ps;
~clock=TempoClock.new(136/60);
~logger = FileLogger.global;
ps = PSProductionSystem(~logger);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, Pop(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, Pop(\stretch, Affine1(3)));
ps.putOp(\truncToBar, Pcomp(Pfindur(4, _)));
ps.putOp(\slice, Pcomp(Pcutdur({16.rand/4}, {16.rand/4}, _)));
ps.putAtom(\amen_break, ~amen_break);
ps.putAtom(\hat, Pobind(\midinote, ~pm.closed_hi_hat));
ps.putAtom(\onebeatrest, PoRest(1));
ps.putAtom(\onebarrest, PoRest(4));
ps.putRule(\timetransform,
	PSChoice(
		2, [\doubleSpeed],
		1, [\halfSpeed],
		2, [\tripleSpeed],
		1, [\thirdSpeed],
	)
);
ps.putRule(\cut, \slice, \amen_break);
ps.putRule(\rush, \timetransform, PSParen(PSStarGeom(3,\cut)));
ps.putRule(\bar, PSBranch(
	[\truncToBar, PSStar(\rush)],
	[\truncToBar, PSStar(\hat)]
), \onebarrest);
ps.putRule(\root, PSStarN(4, \bar));
~ps=ps;
//~patt=Ptrace(ps.root);
~patt=ps.root;
~logger.minPriority = 0;
~patt=Ptrace(ps.root <> (amp: 1, type: \midi, midiout: m, \chan: 0));
~patt.play(~clock);
)
~logger.minPriority=0;
~n=NumberEditorGui;
KrNumberEditor
Editor.for(3).gui;
Editor.for((a: 5)).gui
Pbind(\degree, Instr([\degreeStream,\endlessLeapFrog])).play;
Instr([\degreeStream,\endlessLeapFrog]).next.asCompileString;
~p=Pcutdur(2,3,Pbind(\dur,1));
~p.gui;
~p.asCompileString
Editor.for(Pbind(\dur,1))
~t=Affine1(2,3);
~t.gui;
~t