/*
Server.default = s = ~serverboot.(\internal, \builtin);

//This is the API I want to approximate:

rules = StochLRules.new;
rules.add(\a, 1, [\b, \a]);
rules.add(\a, 9, [\c, \a]);
rules.add(\a, 10, [\c, \a], [\c, \d]); //not yet - is this how branching should go? Or should it be
rules.add(\a, 10, [\[, \c, \a, \], \c, \d); // is this how branching should go? Or 
rules.add(\a, 10, [\c, [\a, \d]]); //I do like that one.

//rules.chomp([\a]); //returns [\b, \a] with probability 0.1, [\c, \a] with probability 0.9
rules.next(\a); //returns [\b, \a] with probability 0.1, [\c, \a] with probability 0.9

mapping = StochMapping.new;
//operator mapping
mapping[\a] = PlazyEnvirN({|dur, pitch| Pbind(\pitch, pitch+1, \dur, dur*2})
//atom mapping
mapping[\a] = Pbind(\pitch, 23, dur, 1)

// These operators and atoms will be composed by <>?


String.rewrite/Plsys
Prewrite
Quarks.gui
redUniverse LSystem
	http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/A-question-abour-LazyLindenmayer-from-MathLib-http://www.fredrikolofsson.com/f0blog/?q=node/388
		file://localhost/Users/dan/Library/Application%20Support/SuperCollider/quarks/NatureToolkit/LSys/Help/LSys.html
PpatRewrite:
	http://www.dewdrop-world.net/words/blog5.php/2011/05/01/neo-complexity-rhythm-generator
	file://localhost/Users/dan/Library/Application%20Support/SuperCollider/quarks/dewdrop_lib/ddwPatterns/Help/PpatRewrite.html
	only appears to rewrite values, not whole events

Plambda versus Penvir
Probably PlazyEnvir does what we , although Some parameters, like duration, cannot be used in the form of an array in the Pbind. For full parallel expansion see PlazyEnvirN.
PG_Cookbook07_Rhythmic_Variations
PG_Cookbook06_Phrase_Network
PG_06g_Data_Sharing
PG_06d_Parallel_Patterns
PG_06b_Time_Based_Patterns
Event types
WeighBag in MathLib
PG_Ref01_Pattern_Internals (c.f. EventStreamCleanup)
Understanding Streams, Patterns and Events - Part 6 (PStretch and FilterPAttern)
PG_08_Event_Types_and_Parameters
recursive_phrasing
Once the parallel pattern starts, there is no way to add more streams to it. To keep adding streams, use Pspawner and Pspawn
*/

////////// recursion learning examples

//native pspawn

/*This example uses Pspawner to trigger overlapping scale segments at different speeds.
Unlike Ppar, which could handle a fixed number before stopping, Pspawner can keep going indefinitely.*/



(
p = Pspawner({ |sp| Ê Ê// sp = the Spawner object
Ê Ê loop {
Ê Ê Ê Ê Ê Ê // run a new pattern in parallel
Ê Ê Ê Ê Ê Ê // the pattern is finite
Ê Ê Ê Ê Ê Ê // after a few events, it stops and the Pspawner forgets about it
Ê Ê Ê Ê sp.par(Pbind(
Ê Ê Ê Ê Ê Ê \degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
Ê Ê Ê Ê Ê Ê \pan, rrand(-1.0, 1.0),
Ê Ê Ê Ê Ê Ê \dur, rrand(0.1, 0.3) Ê Ê// duration is chosen once for each pattern
Ê Ê Ê Ê ));
Ê Ê Ê Ê Ê Ê // tell the Spawner to wait a bit before the next pattern goes
Ê Ê Ê Ê Ê Ê // DO NOT use numBeats.wait for this!
Ê Ê Ê Ê Ê Ê // Everything must go through the Spawner
Ê Ê Ê Ê sp.wait(rrand(1, 4) * 0.25);
Ê Ê }
}).play;
)

p.stop;
The same, written using Pspawn :
(
p = Pspawn(Pbind(
Ê Ê \method, \par, Ê Ê Ê Ê// embed patterns in parallel
Ê Ê Ê Ê // generate the subpattern in a Pfunc (so there's a new pattern each time)
Ê Ê Ê Ê // Pfunc returns the pattern without rendering the stream
Ê Ê Ê Ê // -- important for Pspawn
Ê Ê Ê Ê // See the Pspawn helpfile for other ways to embed patterns
Ê Ê \pattern, Pfunc {
Ê Ê Ê Ê Pbind(
Ê Ê Ê Ê Ê Ê \degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
Ê Ê Ê Ê Ê Ê \pan, rrand(-1.0, 1.0),
Ê Ê Ê Ê Ê Ê \dur, rrand(0.1, 0.3) Ê Ê// duration is chosen once for each pattern
Ê Ê Ê Ê )
Ê Ê },
Ê Ê Ê Ê // The \delta key is used automatically for the spawner.wait() call
Ê Ê \delta, Pwhite(1, 4, inf) * 0.25
)).play;
)

p.stop;


//dewdrop
(
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
)


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
