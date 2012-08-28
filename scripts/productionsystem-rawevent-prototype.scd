/*wherein we attempt to build a CFDG using only native pattern primitives*/
(
PdefAllGui.new;
//Pdef(\note, (note: 0));
//Pdef(\note2, (note: 2));
//native rand style
Pwrand([Pn((note: 5), 2), Pn((note: 0), 1)], [0.5,0.5], inf).play;
//my rand style (just a wrapper to native)
PSwrand([1, Pn((note: 5), 2), 1, Pn((note: 0), 1)], inf).play;
//my rand style (just a wrapper to native)
PSwrand([1, Pn((note: 5), 2), 1, Pn((note: 0), 1)], inf).play;
//my rand style using Pdefs, attempt #1
Pdef(\basicnote, Pbind(\note, 0));
PSwrand([
		1, Pn(Pdef(\basicnote),2),
		1, Pn(Pbindf(Pdef(\basicnote),\note, Pkey(\note)+5),1),
	], inf
).play;
//my rand style using Pdefs, attempt #2
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
PSwrand([
		1, 
		Pn(
			Pdef(\basicnote),
			2
		),
		1,
		Pn(
			Pdef(\basicnote2),
			1
		),
	], inf
).play;
//my rand style using Pdefs, attempt #3
Pdef(\basicnote, Pn(Pbind(\note, 0),2));
Pdef(\basicnote2, Pn(Pbind(\note, 2), 1));
PSwrand([
		1, Pdef(\basicnote),
		1, Pdef(\basicnote2),
	], inf
).play;
//my rand style using Pdefs, attempt #4
Pdef(\basicnote, Pn(Pbind(\note, 0),2));
Pdef(\basicnote2, Pn(Pbind(\note, 2), 1));
Ptrace(Pn(PSwrand([
		1, Pdef(\basicnote),
		1, Pdef(\basicnote2),
	], 1
), inf)).play;
//my rand style using Pdefs, attempt #6
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
Ptrace(PSwrand([
	1, Pbind(
		\type, \phrase,
		\instrument, \basicnote,
	),
	1, Pbind(
		\type, \phrase,
		\instrument, \basicnote2,
		),
], inf)).play;
//my rand style using Pdefs, attempt #7
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
Ptrace(Pwrand(
	[
		Pbind(
			\type, \phrase,
			\instrument, \basicnote,
		),
		Pbind(
			\type, \phrase,
			\instrument, \basicnote2,
		),
	] , [0.5, 0.5], inf
)).play;
//my rand style using Pdefs, attempt #8
Pdef(\basicnote, Pbind(\note, 0, \dur, 0.5));
Pdef(\basicnote2, Pbind(\note, 2, \dur, 0.5));
Ptrace(Pbindf(
	Pwrand(
		[
			Pbind(
				\type, \phrase,
				\instrument, \basicnote,
				\transparency, 0,
			),
			Pbind(
				\type, \phrase,
				\instrument, \basicnote2,
				\transparency, 0,
			),
		] , [0.5, 0.5], inf
	),
	\sustain, 0.5,
	\delta, 1,
)).play;
//Fuck, Pdefs play forever.
Pn(Pbind(
	\type, \phrase,
	\instrument, \basicnote,
	\sustain, 1
),1).play;
//None of this is working; is the secret some weird hack like making inner events into functions?
Pdef(\sweep, { arg sustain=1, n=8, degree=0, ratio=1;
Ê Ê Pbind(
Ê Ê Ê Ê \instrument, \pgrain,
Ê Ê Ê Ê \dur, sustain.value / n,
Ê Ê Ê Ê \degree, Pseq((1..n)) * ratio + 1 + degree.value
Ê Ê )
});
//check Pdef.phraseEventFunc to understand the magic here.
//check also http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/scheduling-patterns-tp7266995p7271549.html
//my rand style using Pdefs, attempt #9
Pdef(\basicnote, Pfindur(1, Pbind(\note, 0, \dur, 0.5)));
Pdef(\basicnote2, Pfindur(1, Pbind(\note, 2, \dur, 0.5)));
Ptrace(Pbindf(
	Pwrand(
		[
			Pbind(
				\type, \phrase,
				\instrument, \basicnote,
				\transparency, 0,
			),
			Pbind(
				\type, \phrase,
				\instrument, \basicnote2,
				\transparency, 0,
			),
		] , [0.5, 0.5], inf
	),
	\sustain, 0.5,
	\delta, 1,
)).play;
//my rand style using Pdefs, attempt #10
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
Ptrace(
	Pwrand(
		[
			Pfindur(1, Pbind(
				\type, \phrase,
				\instrument, \basicnote,
				\transparency, 0,
			)),
			Pfindur(1, Pbind(
				\type, \phrase,
				\instrument, \basicnote2,
				\transparency, 0,
			)),
		],
		[0.5, 0.5],
		inf
	),
).play;
//Yeah! this one works. Pfindur is necessary to truncate these fucking Pdefs.

)
Plambda versus Penvir
Probably PlazyEnvir does what we want, although some parameters, like duration, cannot be used in the form of an array in the Pbind. For full parallel expansion see PlazyEnvirN.
PG_Cookbook07_Rhythmic_Variations
PG_Cookbook06_Phrase_Network
PG_06g_Data_Sharing
PG_06d_Parallel_Patterns
PG_06c_Composition_of_Patterns
PG_Ref01_Pattern_Internals (c.f. EventStreamCleanup)
Understanding Streams, Patterns and Events - Part 6
 - (PStretch and FilterPAttern)
PG_08_Event_Types_and_Parameters
recursive_phrasing (Doesn't implement true arbitrary recursion! is a weird hack that just calls a pattern on itself, and itself *only*)

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
