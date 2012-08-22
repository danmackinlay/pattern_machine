Server.default = s = ~serverboot.(\local, \builtin);
TestPSContext.runAll;

/*
This is the API I want to approximate.

Here I will, for my own sanity, use \CAPITALS for things I intend to be preterminals,
and \lowercase for terminals (i.e. operators or atoms).
This is not enforced by code; you can use whatever convention you'd like.
Things that have no rules are terminals.
*/
(
~productions = PSProductionRuleSet.new;
~productions.add(\A, 2, [\B, \A]);
~productions.add(\A, 3, [\c, \A]);

//productions.add(\A, 10, [\c, [\A, \d]]); // This one should branch.

~productions.rules;
~productions.weights;
~productions.cdfs;
~productions.next(\A);

~productions.next(\A); //returns [\B, \A] with probability 0.4, [\c, \A] with probability 0.6
~productions.next(\A, 0.39);//returns [\B, \A]
~productions.next(\A, 0.99);//returns [\c, \A]
~productions.isTerminal(\A); //false
~productions.isTerminal(\B); //false
~productions.isTerminal(\c); //true

~productions = PSProductionRuleSet.new;
~productions.add(\A, 1, [\a, \B]);
~productions.add(\B, 1, [\b, \C]);
~productions.add(\C, 1, [\c]);
~stream = ~productions.asStream(\A);
~stream.next; // \a
~stream.next; // \b
~stream.next; // \c
~stream.next; // nil

~productions.add(\c, 1, [\d, \A]);
~stream = ~productions.asStream(\A);
~stream.next; // \a
~stream.next; // \b
~stream.next; // \d
~stream.next; // \a
~stream.next; // \b
~stream.next; // \d

~stream = ~productions.asStream(\A); 
~manySteps = 999.collect({~stream.next;}); //can we pop the stack by recursing in this fashion?
[\a, \b, \d].dup(333).flat == ~manySteps; //true

//how does this generalise to polyphony?
)


coding = PSProductionCoding.new;
//operator coding
coding[\c] = [\operator, Pbindf(_, \pitch, Pkey(\pitch) +2)]
coding[\c] = [\operator, Padd(\pitch, 2, _)]
//coding[\c] = [\operator, PlazyEnvirN({|dur, pitch| Pbind(\pitch, pitch+1, \dur, dur*2})]
//atom coding
coding[\d] = [\atom, Pbind(\pitch, 23, dur, 1)]
//coding[\a] = [\atom, Pbind(\pitch, 23, dur, 1)] //no coding so not a terminal?

/*
Who knows about terminality? ProductionRuleSets or codings?
By analogy with EBNF, only ProductionRuleSets.
A terminal is anything without a rewrite rule. Everything else is a Preterminal.
*/

productions.words

context = PSContext.new(coding);
context.apply(productions.next(\A));

productionplayer = PSProductionSpawner.new;


/*
We will likely need affine transform objects to hold the current transform context.
This is  so that affine functions can be curried without wasting stack.
Maybe I can get away without those for now and build something optimised for affine transforms as needed.
Also, memoisation might get us there (?).

Should we be able to play Patterns in Contexts as well?
Would be lots of work; ignore for now.
Work around by playing events with recursive patterns Prewrite-style

These operators and atoms will be composed by something like <>?
No, it is close but not right.

There is an asymmetry here - the (time)shift operator.
Since all productions need to schedule themselves
(that is, i'd like them to) they need to have an idea of setting a note length
Since time passes, that "state" is tracked for us automatically.

This is surprisingly fiddly, because Events have default values. see also Pstretch.

We would like state more generally to collapse for us into polite flat context dictionaries.
The context should be enough to know which note to play on next, and what default params to be working with.
We can't really keep stacks of the fucking things lying about.
although we prolly could if we ditched tail recursion.
This will need a StatefulEvent, which should emit a PLazyEnvirN that transforms patterns appropriately.
or a PeventMod.

A pity, because otherwise Environment has great stack push/pop methods that would be
easy to work with. Maybe we still could?
*/


/*
 *other implementations
 */
String.rewrite
Plsys
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
Probably PlazyEnvir does what we , although some parameters, like duration, cannot be used in the form of an array in the Pbind. For full parallel expansion see PlazyEnvirN.
PG_Cookbook07_Rhythmic_Variations
PG_Cookbook06_Phrase_Network
PG_06g_Data_Sharing
PG_06d_Parallel_Patterns
PG_06c_Composition_of_Patterns
Event types
WeighBag in MathLib
PG_Ref01_Pattern_Internals (c.f. EventStreamCleanup)
Understanding Streams, Patterns and Events - Part 6
 - (PStretch and FilterPAttern)
PG_08_Event_Types_and_Parameters
Pdef
recursive_phrasing

Once the parallel pattern starts, there is no way to add more streams to it. To keep adding streams, use Pspawner and Pspawn

These patterns remain in the library mainly for reasons of backward compatibility, since their behavior can be replicated easily using Pbindf.
Pset(name, value, pattern)	Pbindf(pattern, name, value)
Padd(name, value, pattern)	Pbindf(pattern, name, Pkey(name) + value)
Pmul(name, value, pattern)	Pbindf(pattern, name, Pkey(name) * value)
The patterns Psetpre, Paddpre, and Pmulpre reverse the order of evaluation. Pchain is able to duplicate this functionality.

http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Pfindur-with-a-Pattern-for-the-duration-tp7579205p7579235.html
*/


////////// recursion learning examples

//native pspawn

/*This example uses Pspawner to trigger overlapping scale segments at different speeds.
Unlike Ppar, which could handle a fixed number before stopping, Pspawner can keep going indefinitely.*/



(
p = Pspawner({ |sp| 	// sp = the Spawner object
	loop {
			// run a new pattern in parallel
			// the pattern is finite
			// after a few events, it stops and the Pspawner forgets about it
		sp.par(Pbind(
			\degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
			\pan, rrand(-1.0, 1.0),
			\dur, rrand(0.1, 0.3) 		// duration is chosen once for each pattern
		));
			// tell the Spawner to wait a bit before the next pattern goes
			// DO NOT use numBeats.wait for this!
			// Everything must go through the Spawner
		sp.wait(rrand(1, 4) * 0.25);
	}
}).play;
)

p.stop;
The same, written using Pspawn :
(
p = Pspawn(Pbind(
	\method, \par, 	// embed patterns in parallel
		// generate the subpattern in a Pfunc (so there's a new pattern each time)
		// Pfunc returns the pattern without rendering the stream
		// -- important for Pspawn
		// See the Pspawn helpfile for other ways to embed patterns
	\pattern, Pfunc {
		Pbind(
			\degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
			\pan, rrand(-1.0, 1.0),
			\dur, rrand(0.1, 0.3) // duration is chosen once for each pattern
		)
	},
		// The \delta key is used automatically for the spawner.wait() call
	\delta, Pwhite(1, 4, inf) * 0.25
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
