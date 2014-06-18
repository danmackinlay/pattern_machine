///
/// Leverage General MIDI to get a rapid demonstration piece
///
(
//understand
Event.partialEvents[\pitchEvent].pairsDo({|k,v|[k,v].postln;});
Event.partialEvents[\midiEvent].pairsDo({|k,v|[k,v].postln;});
Event.partialEvents[\midiEvent][\midiEventFunctions].pairsDo({|k,v|[k,v.asCompileString].postln;"====".postln;});
26.asMIDINote
)
(
//init
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
//m.latency=0;
)
Pop(\a, Affine1(2)) <> Pop(\a, Affine1(2,1)) <> Pop(\a, 1)

(
//test
a = Ptrace(Pbind(
	\degree, Pseq([1, 2, 3, [0, 5]], inf),
	//\bend, Pwhite(0, 76, inf),
	\amp, 1.0));
(a <> (type: \midi, midiout: m, \chan: 0)).play;
)
GeneralMIDIPercMap.low_tom_1
(
var ps;
~logger = PostLogger.new;
ps = PSProductionSystem(~logger);
~clock=TempoClock.new(150/60);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, Pop(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, Pop(\stretch, Affine1(3)));
ps.putOp(\upmin3, Pop(\note, Affine1(1, 3)));
ps.putOp(\upmaj3, Pop(\note, Affine1(1, 4)));
ps.putOp(\downmin3, Pop(\note, Affine1(1, -3)));
ps.putOp(\downmaj3, Pop(\note, Affine1(1, -4)));
//SambaTwoPart.mid
ps.putAtom(\sambarhythm1, Pbind(\midinote, GeneralMIDIPercMap.cabasa, \dur, Pseq([1/2, 1/4, 1/4, 1/2, 1/4, 1/2, 1/2, 1/4, 1/2, 1/2])));
ps.putAtom(\sambarhythm2, Pbind(
	\note, Pseq([23, 26, 26, 23, 26, 26, 23, 23, 26, 26, 23, 26, 26, 23]),
	\dur, Pseq([3/4, 1/4, 1, 3/4, 1/4, 1/2, 1/2, 3/4, 1/4, 1, 3/4, 1/4, 1, 3/4, 1/4, 1/2, 1/2]))
);
//http://www.sambatida.co.uk/The%20music/index.html
ps.putAtom(\surdorhythm1,
	Pbind(\midinote, Pseq([GeneralMIDIPercMap.low_tom_1, GeneralMIDIPercMap.mid_tom_1]), \dur, 2));
//see also
//http://www.artdrum.com/RHYTHMS_SAMBA_FOR_KIDS.htm
//http://www.littledrum.co.uk/batucada.htm
ps.putAtom(\note, Pobind(\note, 0, \harmonic, 1, \legato, 2, \dur, 1, \pan, 0));
ps.putAtom(\onebeatrest, PoRest(1));

ps.putRule(\bar,
	PSBranch(
		[\sambarhythm1, \sambarhythm1],
	),
	\sambarhythm2);
ps.putRule(\root, PSStar(\bar));
~ps=ps;
~patt=Ptrace(Pbind(\midinote, Pkey(\note)+12)<> ps.root <> (amp: 1, type: \midi, midiout: m, \chan: 9));
~logger.minPriority = 2;
~patt.play(~clock);
)
~logger.minPriority=0;
