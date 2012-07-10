/*
Quarks.gui
String.rewrite/Plsys
Prewrite
Quarks.gui
redUniverse LSystem
http://www.digipedia.pl/usenet/thread/11165/26516/
file://localhost/Users/dan/Library/Application%20Support/SuperCollider.35/quarks/NatureToolkit/LSys/Help/LSys.html
PpatRewrite  http://www.dewdrop-world.net/words/blog5.php/2011/05/01/neo-complexity-rhythm-generator file://localhost/Users/dan/Library/Application%20Support/SuperCollider.35/quarks/dewdrop_lib/ddwPatterns/Help/PpatRewrite.html
http://www.digipedia.pl/usenet/thread/11165/26516/
http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/A-question-abour-LazyLindenmayer-from-MathLib-td3718965.html
http://www.fredrikolofsson.com/f0blog/?q=node/388

Plambda versus Penvir
Probably PlazyEnvir does what we , although Some parameters, like duration, cannot be used in the form of an array in the Pbind. For full parallel expansion see PlazyEnvirN.
PG_Cookbook07_Rhythmic_Variations
PG_Cookbook06_Phrase_Network
PG_06g_Data_Sharing
PG_06d_Parallel_Patterns
PG_06b_Time_Based_Patterns
Event types
PG_Ref01_Pattern_Internals (c.f. EventStreamCleanup)
Understanding Streams, Patterns and Events - Part 6 (PStretch and FilterPAttern)
PG_08_Event_Types_and_Parameters
recursive_phrasing

////////// recursion learning examples
p = Ppar(
    { |i|
        Pbind(
            \pan, i*2 - 1,
            [\dur, \level], PpatRewrite(
                Pn([4, 0], 1),  // input pattern
                Pseries(1+i, 1, inf).fold(1, 4),
                [
                    nil -> { |item, level|
                        var    subdiv = rrand(2, 5);
                        if(0.75.coin) {
                            Ptuple([
                                Pseq(item[0] / subdiv *
                                    subdiv.partition((subdiv * 0.7)
                                        .roundUp.asInteger, 1), 1),
                                Pseq([item[1], Pn(level, inf)])
                            ])
                        } { Pn(item, 1) }
                    }
                ]
            ),
            \freq, Pexprand(100, 220, inf) * (2 ** (Pkey(\level) - 1)),
            \sustain, 2 ** (Pkey(\level).neg)
        )
    } ! 2
).play(quant: 1);



(
var	intervals = Pseries(
	0,
	Pwrand(#[-2, -1, 1, 2], #[0.1, 0.2, 0.4, 0.3], inf),
	Pwrand(#[2, 3, 4, 5], #[0.4, 0.3, 0.2, 0.1], inf).asStream
);
p = Pbind(
	\root, 7,
	[\degree, \level], PpatRewrite(
		Ptuple([Pseq(#[2, 5, 4], 1), 0]),
		Pseries(0, 1, 5),
		[
			// intervals is biased upward, so this should tend to rise
			{ |item| item[0] <= 0 } -> { |item, level|
				Ptuple([
					item[0] + intervals,
					Pseq([item[1], Pn(level, inf)])
				])
			},
			// and '-', applied to a higher note, should tend to fall
			{ |item| item[0] > 0 } -> { |item, level|
				Ptuple([
					item[0] - intervals,
					Pseq([item[1], Pn(level, inf)])
				])
			},
		]
	),
	// 2**(1-0) = 2, 2**(1-1) = 1, 2**(1-2) = 0.5 etc.
	\dur, 2 ** (1 - Pkey(\level)),
	\amp, (Pkey(\level) + 1).reciprocal * 0.5,
	\octave, Pkey(\level) + 3
).play;
)
