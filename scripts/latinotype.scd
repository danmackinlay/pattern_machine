///
/// Leverage General MIDI to get a rapid demonstration piece
///

Event.partialEvents[\midiEvent].pairsDo({|k,v|[k,v].postln;});
Event.partialEvents[\midiEvent][\midiEventFunctions].pairsDo({|k,v|[k,v.asCompileString].postln;"====".postln;});
MIDIClient.init
MIDIClient.destinations
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
m.asCompileString
//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
//m.latency=0;
a = Ptrace(Pbind(
	\degree, Prand([1, 2, 3, [0, 5]], inf),
	//\bend, Pwhite(0, 76, inf),
	\amp, 1.0));
(a <> (type: \midi, midiout: m, \chan: 0)).play;
//m.noteOn (chan:0, note: 62, veloc: 127);

(
var ps;
~logger = PostLogger.new();
ps = PSProductionSystem(~logger, trace:true);
~clock=TempoClock.new(108/60);
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, POp(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, POp(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, POp(\stretch, Affine1(3)));
ps.putOp(\h3on2, POp(\harmonic, Affine1(3/2)));
ps.putOp(\h4on3, POp(\harmonic, Affine1(4/3)));
ps.putOp(\h2on3, POp(\harmonic, Affine1(2/3)));
ps.putOp(\h3on4, POp(\harmonic, Affine1(3/4)));
ps.putOp(\rotateRight, POp(\pan, (_+0.25).wrap(-1,1)));
ps.putOp(\rotateLeft, POp(\pan, (_-0.25).wrap(-1,1)));

ps.putAtom(\note, Pobind(\note, 0, \harmonic, 1, \legato, 2, \dur, 1, \pan, 0));
ps.putAtom(\onebeatrest, PoRest(1));

ps.putRule(\ornament,
	PSChoice(
		1, [\note],
		2, [\timetransform, \freqtransform, \rotate, PSParen(\note, \ornament)]
	)
);
ps.putRule(\timetransform,
	PSChoice(
		2, [\doubleSpeed],
		1, [\halfSpeed],
		2, [\tripleSpeed],
		1, [\thirdSpeed],
	)
);
ps.putRule(\freqtransform,
	PSStarN(1, PSChoice(
		4, [\h3on2],
		2, [\h4on3],
		4, [\h2on3],
		2, [\h3on4],
	))
);
ps.putRule(\rotate,
	PSChoice(
		1, [\rotateRight],
		1, [\rotateLeft],
	)
);
ps.putRule(\bar,
	PSBranch(
		[\ornament],
	),
	\onebeatrest, \onebeatrest);
ps.putRule(\root, PSStar(\bar));
~ps=ps;
//~patt=Ptrace(ps.root);
~patt=ps.root;
~logger.minPriority = 2;
~patt.play(~clock);
)
~logger.minPriority=0;
