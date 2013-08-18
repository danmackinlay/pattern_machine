
//This one is trying to be a breakbeat guy.
//NB - am not sure that the \truncatetobar operator is behaving from within the pattern. should test.
//Also, timetransform is not repeatedly applied.
TestProductionSystem.runAll;
PSTestPattern.runAll;
(
//percussion synth
~synthprog = ~pm +/+ "ext/microtonic.trak";
"open -g %".format(~synthprog).unixCmd;
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
//m.latency=0;
//m.noteOn(0,36,127);
//~pm = GeneralMIDIPercMap;
~pm = MicrotonicMIDIPercMap;
~amen_break = Ppar([
	Pbind(\midinote, ~pm.ride_cymbal_1, \dur, Pser([1/2],8), \amp, 1/2),
	Pbind(
		\midinote, Pseq(~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(3) ++ ~pm.bass_drum_1.dup(2) ++ ~pm.snare_drum_1.dup(1)),
		\dur, Pseq([1/2, 1/2, 3/4, 1/2, 1/4, 1/4, 1/4, 3/4, 1/4])
	)
]);
)
(
~clock=TempoClock.new(136/60);
~patt=Ptrace(~amen_break <> (amp: 1, type: \midi, midiout: m, \chan: 0));
~patt.play(~clock);
)
(
var ps;
~clock=TempoClock.new(136/60);
~logger = FileLogger.global;
//~logger = NullLogger.global;
//~logger = PostLogger.global;
ps = PSProductionSystem(~logger);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, Pop(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, Pop(\stretch, Affine1(3)));
ps.putOp(\truncToBar, Pcomp(Pfindur(4, _)));
ps.putOp(\slice, Pcomp(Pcutdur(0, {4.rand}, _)));
ps.putAtom(\amen_break, ~amen_break);
ps.putAtom(\hat, Pobind(\midinote, ~pm.closed_hi_hat, \dur, 1/2));
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
//this does not appear to actually apply arbitrarily many transforms.
ps.putRule(\rush, PSStarGeom(5,\timetransform), \cut);
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
//Editor.for((a: 5)).gui
~p=Pcutdur(2,3,Pbind(\dur,1));
~p.gui;

////////////////////////////////////////////////////////////////////////////
///////////////Diagnosis////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
(
fork {
	//DLS synth init
	"open -g -a SimpleSynth".unixCmd;
	0.5.wait;
	MIDIClient.init;
	MIDIClient.destinations;
	m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
	//m = MIDIOut.newByName("SimpleSynth virtual input", "SimpleSynth virtual input");
	m.latency=0;
	m.noteOn(0,48,127);
	m.noteOff(0,48,127);

	~rise = Ppar([
		Pbind(\midinote, 36, \dur, Pser([1/2],8), \amp, 1/2),
		Pbind(
			\midinote, Pseq(48+[0,1,2,3,4,5,6,7]),
			\dur, Pseq((1/2).dup(8))
		)
	]);
}
)

(
~clock=TempoClock.new(136/60);
~patt=Ptrace(~rise <> (amp: 1, type: \midi, midiout: m, \chan: 0));
~patt.play(~clock);
)

(
var ps;
~clock=TempoClock.new(136/60);
~logger = FileLogger.global;
//~logger = NullLogger.global;
//~logger = PostLogger.global;
ps = PSProductionSystem(~logger);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putOp(\thirdSpeed, Pop(\stretch, Affine1(1/3)));
ps.putOp(\tripleSpeed, Pop(\stretch, Affine1(3)));
ps.putOp(\truncToBar, Pcomp(Pfindur(4, _)));
ps.putOp(\slice, Pcomp(Pcutdur(0, {4.rand}, _)));
ps.putAtom(\amen_break, ~rise);
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
//this does not appear to actually apply arbitrarily many transforms.
ps.putRule(\rush, PSStarGeom(5,\timetransform), \cut);
ps.putRule(\bar, PSBranch(
	[\truncToBar, PSStar(\rush)],
//	[\truncToBar, PSStar(\hat)]
), \onebarrest);
ps.putRule(\root, PSStarN(4, \bar));
~ps=ps;
//~patt=Ptrace(ps.root);
~patt=ps.root;
~logger.minPriority = 0;
~patt=Ptrace(ps.root <> (amp: 1, type: \midi, midiout: m, \chan: 0));
~patt.play(~clock);
)