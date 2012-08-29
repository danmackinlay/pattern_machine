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
//my rand style using Pdefs, more succinct using my own classes - attempt #11
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
PSwrand(
	[
		1, Pfindur(1, Pbind(
			\type, \phrase,
			\instrument, \basicnote,
		)),
		1, Pfindur(1, Pbind(
			\type, \phrase,
			\instrument, \basicnote2,
		)),
	],
	inf
).play;

//PatternProxy source implies that this embedding only goes on as long as it the sub-pattern receives input events. So why does Pdef receive infinite sub-events?
//Does EmbedOnce stop that?
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
PSwrand(
	[
		1, EmbedOnce(Pbind(
			\type, \phrase,
			\instrument, \basicnote,
		)),
		1, EmbedOnce(Pbind(
			\type, \phrase,
			\instrument, \basicnote2,
		)),
	],
	inf
).play;//nope
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
PSwrand(
	[
		1, OneShotStream((
			\type: \phrase,
			\instrument: \basicnote,
			\delta: 1,
		)),
		1, OneShotStream((
			\type: \phrase,
			\instrument: \basicnote2,
			\delta: 1,
		)),
	],
	5
).play;//explodes if you set repeats to inf, also only repeats each once.
//
Pdef(\basicnote, Pbind(\note, 0));
Pdef(\basicnote2, Pbind(\note, 2));
PSwrand(
	[
		1, (
			\type: \phrase,
			\instrument: \basicnote,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote2,
		),
	],
	inf
).play;
//oh shit, Pbind *sometimes* plays forever.
Pbind(\note, 0).play;
//So this works:
Pdef(\basicnote, (\note: 0));
Pdef(\basicnote2, (\note: 2));
PSwrand(
	[
		1, (
			\type: \phrase,
			\instrument: \basicnote,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote2,
		),
	],
	inf
).play;
//Thus:
Pdef(\basicnote, (\note: 0));
Pdef(\basicnote2, (\note: 2));
Pdef(\basicnote3, Pn((\note: 5, \delta: 1/2), 4));
PSwrand(
	[
		1, (
			\type: \phrase,
			\instrument: \basicnote,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote2,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote3,
		),
	],
	inf
).play; //Doesn't work in full generality
// \basicnote3 truncates to 2 instead of 4 notes
//Compare with Pdef-freeness, which doesn't need to know how long to play for, but can't repeat within the patterns:
~basicnote = (\note: 0);
~basicnote2 = (\note: 2);
~basicnote3 = (\note: 5, \delta: 1/2);
PSwrand(
	[
		1, ~basicnote,
		1, ~basicnote2,
		1, ~basicnote3,
	],
	inf
).play; 
//Let's try untruncated Pdefs. Will this leak?:
Pdef(\basicnote, (\note: 0));
Pdef(\basicnote2, Pn((\note: 2, \delta: 1/4), 6));
Pdef(\basicnote3, Pn((\note: 5, \delta: 1/2), 4));
PSwrand(
	[
		1, (
			\type: \phrase,
			\instrument: \basicnote,
			\sustain: inf,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote2,
			\sustain: inf,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote3,
			\sustain: inf,
		),
	],
	inf
).play; //yep, that leaks, fast
//Let's try untruncated Pdefs. Will this leak?:
Pdef(\basicnote, (\note: 0, \sustain: 1));
Pdef(\basicnote2, Pn((\note: 2, \delta: 1/4, \sustain: 1), 6));
Pdef(\basicnote3, Pn((\note: 5, \delta: 1/2, \sustain: 1), 4));
Ptrace(PSwrand(
	[
		1, (
			\type: \phrase,
			\instrument: \basicnote,
			\sustain: inf,
			\transparency: 0,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote2,
			\sustain: inf,
			\transparency: 0,
		),
		1, (
			\type: \phrase,
			\instrument: \basicnote3,
			\sustain: inf,
			\transparency: 0,
		),
	],
	inf
)).play; //yep, that leaks, but not how i thought, very slowly. What is going on?
/*
 *Summary:
 Pdefs play forever. So you can use them as an inner event, but
 you have to choose beforehand how long they will play for.
 Vanilla events, on the other hand, know how long they go for,
 but only schedule a single "event".
 So, in between we need to know about some events that can schedule themselves
 and have arbitrary length. PlazyEnvirN?
 
 Other notes discovered in the course of this:
 
 Plambda creates a scope for embedded patterns. Hmmmm. (How does it
 compare to Penvir?)
 PlazyEnvirN allows parallel expansion of event patterns.
 Parallelisation:
 	Understanding Streams, Patterns and Events - Part 6
 	PG_06d_Parallel_Patterns
 
 List of event keys of note:
 	PG_08_Event_Types_and_Parameters
 	Pbind
 	Event
 
 Replicating Pset/Padd/Pmul with Pbindf:
 	Padd(name, value, pattern)
 		Pbindf(pattern, name, Pkey(name) + value)
 Replicating Psetpre/Paddpre/Pmulpre with Pbindf: (something like this)
 	Paddpre(name, value, pattern)
 		pattern <> Pbindf(pattern, name, Pkey(name) + value)

 */

)


http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Pfindur-with-a-Pattern-for-the-duration-tp7579205p7579235.html
*/


////////// Other learning examples

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

