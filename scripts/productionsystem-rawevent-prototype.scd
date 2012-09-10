/*wherein we attempt to build a CFDG using only native pattern primitives*/
(
//native rand style
Pwrand([Pn((note: 5), 2), Pn((note: 0), 1)], [0.5,0.5], inf).play;
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
	Pbind(
		\instrument, \pgrain,
		\dur, sustain.value / n,
		\degree, Pseq((1..n)) * ratio + 1 + degree.value
	)
});
//check Pdef.phraseEventFunc to understand the magic here.
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
//Note the Pfindur's parameter is in some sense "special" - it can use a sptream but not an argument, for Deep Reasons.
//http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Pfindur-with-a-Pattern-for-the-duration-td7579205.html#a7579235
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
//Let's try untruncated Pdefs plus \sustain. Will this leak?:
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
 * Summary:
 
Pdefs play forever. So you can use them as an inner event, but
you have to choose beforehand how long they will play for.
Vanilla events, on the other hand, know how long they go for,
but only schedule a single "event".
So, in between we need to know about some events that can schedule themselves
and have arbitrary length not decided in advance. PlazyEnvirN?
 
 * Other notes discovered in the course of this:

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
		~delta defaults to ~dur * ~stretch
		~sustain defaults to ~dur * ~stretch * ~legato
Replicating Pset/Padd/Pmul with Pbindf:
	Padd(name, value, pattern)
		Pbindf(pattern, name, Pkey(name) + value)
Replicating Psetpre/Paddpre/Pmulpre with Pbindf: (something like this)
	Paddpre(name, value, pattern)
		pattern <> Pbind(name, Pkey(name) + value)
 */
)
(
//PLazyEnvirN/Penvir excercises
//Pfunc is nice enough - you can get at Penvir environment using ~ syntax.
x = (a:8);
y = Penvir(
	x,
	Pfunc { ~a * 2 }
);
5.do({y.asStream.next.postln});
)
//Can we just use functions?
(
x=(\delta: 1);
y=Ptrace(Penvir(
	x,
	Pn(Pbind(
		\delta, {~delta/2},
		\note, 0,
	), 5)
));
5.do({y.asStream.next(Event.default).postln});
y.play; //apparently not; this only plays once. \delta 0?
)
// how about Prout?
(
x=(\delta: 1);
y=Penvir(
	x,
	Pn(Pbind(
		\delta, Prout {(~delta/2).yield},
		\note, 0,
	), 5)
);
5.do({y.asStream.next(Event.default).postln});
y.play;
//Well, that was OK.
)
(
//But inside the routine, can we embed nested patterns in a natural fashion?
(
x=(\delta: 1);
y=Penvir(
	x,
	Pn(
		Prout({
			2.do({currentEnvironment.postln;~delta.postln;x.yield;});
		}),
		2
	)
);
//The events postln'd inside each of these are ()
//it seems that currentEnvironemnt don't work. I think it is being Environment.use'd.
y.asStream.next(Event.default);
y.play(nil, Event.default);
)
(
w=Prout {(~delta/2).yield};
v=Ptrace(Penvir(
	(note:0, delta:1),
	Pn(w, 5)
)).play; //yields only numbers. no easy way to get the defaultenv.
)
(
//Fuck it, PlazyEnvirN, then.
x=PlazyEnvirN({|pat, rate=1|
	[\x, pat, rate].postln;
	Pstretch(rate,
		Pseq([
			(\delta:1),
			Pbindf(pat, \note, Pkey(\note) +2)
		])
	);
});
y=PSwrand([
	2, x,
	1, (note:0)
]);
(y <> (rate: 0.5, pat: y)).play;
//Doesn't get stretched on successive applications! Piss and fury.
)
/*Argh, OK the contortions my brain is going through to make this go are ill omens for this approach.
Trying from a different angle, let's think about behaviours of the state machine which makes a hypothetical sequence go. */
~doubleSpeed = {|i| i.put(\delta, i[\delta]*2);};
~machine = ProductionMachine(
	transformMap:(\z: ~halfStep),
	atomMap:(
		\a: (note: 0, sustain:1, dur:1),
		\b: Rest(1),
	),
	ruleMap:(),
);
~machine.produce([\z, \b, \a]); //should play \a, \b, in order at double speed
//(aside: when does time advance?
~machine.produce([\z, \b, \a], [\C]); //should play \a, \b, in order at double speed, and, concurrently, C.
/*
If we want nice things like specifiable associativity, Kleene stars and the like, we are building a DSL already. Could be worth building operators as functions.

~doubleSpeed.(\a,\b,\c) lazily applys ~doubleSpeed to all of the functions.But then it's just patterns again, except with operators we don't *quite* have yet
changeTick(ratio, subrule), transpose(transposition, subrule)
We *nearly* have those things, though. there is a close correspondence between Terminals, and Events, and between Preterminals and Patterns. A CFDG looks like it *should* be a Pattern. But it doesn't *quite* work at the moment

Let's define some transforms and atoms as if that were going to work:
*/
~transpose = {|interval, pattern| Pbindf(pattern, \note, Pkey(\note)+interval);};
~stretch = {|ratio, pattern| Pstretch(ratio, pattern);};
~repeat = {|reps, pattern| Pn(pattern, reps);};//for consistency
~aNote = (note:0, dur:1);
~aRest = Rest(1);
~repeat.(4, ~aNote).play;
~repeat.(4, ~stretch.(0.5, ~aNote)).play;//gets stuck forever! (Pstretch doesn't work on events?) TODO: fix Pstretch
~stretch.(0.5, ~repeat.(4, ~aNote)).play;//works fine
//Then we want some rules:
Pn(Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest]),inf).play;//also gets stuck forever - Events get cast to infinite streams?
~aNote = Pn((note:0, dur:1),1);
~aNoteDelta = Pn((note:0, dur:1),1);
Pn(Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest]),inf).play;//works OK but…
Pstretch(0.5, Pn(Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest]),inf)).play;//doesn't get stuck, but doesn't timestretch.
~stretchdelta = {|ratio, pattern| Ptrace(Pbindf(pattern, \delta, Pkey(\delta)*ratio), prefix: \inner);};//bah! Pstretch isn't working...
Ptrace(~stretchdelta.(0.5, Ptrace(Pn(Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest]),inf)))).play;//doesn't work. Is silent. Piffle
Ptrace(~stretchdelta.(0.5, Pseq([Pbind(\note, 0.5, \delta, 0.5), Rest(1)],4))).play; //works OK
Pstretch(0.5, Pseq([Pbind(\note, 0.5, \delta, 0.5), Rest(1)],4)).play; //works at half the rate of the above.
~stretchall = {|ratio, pattern| Pbindf(pattern, \delta, Pkey(\delta)*ratio, \dur, Pkey(\dur)*ratio);};
Ptrace(~stretchall.(0.5, Pseq([Pbind(\note, 0.5, \delta, 0.5), Rest(1)],4))).play; //halves tempo
Ptrace(Pstretch(0.5, Pseq([Pbind(\note, 0.5, \delta, 0.5), Rest(1)],4))).play; //works OK
Ptrace(Pstretch(0.5, Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest],4))).play; //works OK
Ptrace(Pstretch(0.25, Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest],4))).play; //works OK
Ptrace(~stretchdelta.(0.25, Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest],4))).play; //Why does this no work?
Ptrace(~stretchdelta.(0.25, Pseq([~aNoteDelta, ~aRest, ~transpose.(3, ~aNoteDelta), ~aRest],4))).play; //Why does this no work?
~stretchdelta.(0.25, Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest],4)).asStream.next(Event.default);
Pseq([~aNote, ~aRest, ~transpose.(3, ~aNote), ~aRest],4).asStream.next(Event.default).play;

//FINE! Pspawner! But how do we pass in a context array to such a spawner?
//So to make this work with Pspawner, we want to know about the default event passed in to EventStreamPLayer, and have //Note there is some good material about this in the Pspawn help files, which refers to Preterminal and Terminal events as Parent and Child events. (or, one might almost say, Pattern and Event)
//There is not even really a reason to have the same transforms applied to each type of event. We might want to trigger the patterns more closely together but leave the notes the same length. Hmm.
//How do we do this? Do we pass in a context to each rule expressor to which everything below is relative?
(
p = Pspawner({ |sp|
	loop {
		sp.par(PContext(
			(\delta: 1, note:0),
			Pn(_, 4)
		));
		sp.wait(rrand(1, 4) * 0.25);
	}
}).play;
// it will play "patterns" nominally, but in practice it seems to be ok with things that respond to "asStream" or "embedInStream".
// I might be able ot get there with discipline and Pchain (which will also cast Events). The problem is then how to embed Pspawners in each other. Pfunc?
(Pbind(\delta, Pkey(\delta) / Prand([1,2,3], inf) <> (\delta: 1))).play;
//So I find myself unexpectely back with Pchain after all, as it turns out that Pbind+Pkey+Pchain gets us
// a composed transform. We can even build chains of transforms of partially applied functions.
~doubleSpeed = Pbind(\delta, Pkey(\delta) / 2);
//Or, complimentarily and in a different style: - http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/filter-patterns-and-Pkey-td6277050.html
~halfSpeed = Pfunc {~delta = ~delta * 2};
~changingSpeed = Ptrace(PSwrand([1, ~doubleSpeed, 1, ~halfSpeed]) <> Pn((\delta:1),inf)).play;
~changingSpeed = Ptrace(PSwrand([1, ~doubleSpeed, 1, ~halfSpeed]) <> Pn((\delta:1),inf)).play;
//But how does one know when a measure is completed? How does one know when to spawn something new? These all modify events, but we want to modify events and also gestures/phrases. (Pspawn help has some word of wisdom - search for "hint")

//Sounds like I'm still going to need to write my own scheduler? Although I think Pspawner can be imposed upon to do the right compositing.

//In fact, Pspawn can probably be so imposed also - it makes new patterns, right?

(
~bar = Pbind(\note, Pseq([1,2,3]), \delta, 1);
~root = Pspawner({ |sp|	// sp = the Spawner object
	var iter = 0;
	loop {
		sp.seq(Prand([~bar, ~doubleSpeed.(~bar)]));
		iter = iter +1;
		iter.postln;
		//sp.wait(rrand(1, 4) * 0.25);
	}
});
~root.play; //never changes speed!
)
(
~bar = Pbind(\note, Pseq([1,2,3]), \delta, 1);
~root = Pspawner({ |sp|	// sp = the Spawner object
	var iter = 0;
	loop {
		sp.seq([~bar, ~doubleSpeed.(~bar)].choose);
		iter = iter +1;
		iter.postln;
		//sp.wait(rrand(1, 4) * 0.25);
	}
});
~root.play;
)
////////// Other learning examples
//native pspawner
/*This example uses Pspawner to trigger overlapping scale segments at different speeds.
Unlike Ppar, which could handle a fixed number before stopping, Pspawner can keep going indefinitely.
See ddw on Pspawner hacks: http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/scheduling-patterns-td7266995.html#a7271549
*/
(
p = Pspawner({ |sp|	// sp = the Spawner object
	loop {
		// run a new pattern in parallel
		// the pattern is finite
		// after a few events, it stops and the Pspawner forgets about it
		sp.par(Pbind(
			\degree, Pseries(rrand(-5, 7), #[-1, 1].choose, rrand(4, 7)),
			\pan, rrand(-1.0, 1.0),
			\dur, rrand(0.1, 0.3)		// duration is chosen once for each pattern
		));
			// tell the Spawner to wait a bit before the next pattern goes
			// DO NOT use numBeats.wait for this!
			// Everything must go through the Spawner
		sp.wait(rrand(1, 4) * 0.25);
	}
}).play;
)
p.stop;
//The same, written using Pspawn :
(
p = Pspawn(Pbind(
	\method, \par,	// embed patterns in parallel
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
// More instructive:
// Play parallel scales in the left channel and sequentially-arranged scales in the right
// This means parallelizing (Ppar) the child streams; thus Ppar surrounds a pair of Pspawns

// Handling of \pan is interesting: \pan needs to be a property of the patternChoices items
// It is NOT a property of the spawning events
// To reuse patternChoices, the Pspawns wrap the base patterns in a Pbindf, which adds new values

(
var    patternChoices = (
    up: { Pbind(\degree, Pseries(rrand(-4, 5), 1, rrand(4, 10)), \dur, 0.125) },
    down: { Pbind(\degree, Pseries(rrand(4, 11), -1, rrand(4, 10)), \dur, 0.125 * 4/3) }
);

p = Ppar([
    Pspawn(Pbind(
            // intermediate value
        \patternKey, Prand([\up, \down], inf),
            // pattern is selected and pan applied here
        \pattern, Pfunc { |ev| Pbindf(ev.dict[ev.patternKey].value, \pan, -1) },
        \delta, Pwhite(1, 5, inf) * 0.125,
        \method, \par
    ), (dict: patternChoices)),
    Pspawn(Pbind(
        \patternKey, Prand([\up, \down], inf),
        \pattern, Pfunc { |ev| Pbindf(ev.dict[ev.patternKey].value, \pan, 1) },
        \delta, Pwhite(1, 5, inf) * 0.125,
        \method, \seq
    ), (dict: patternChoices)),
]).play;
)

p.stop;

//PLazyEnvirN:
(
SynthDef(\help_sinegrain,
	{ arg out=0, freq=440, sustain=0.05, pan=0;
		var env;
		env = EnvGen.kr(Env.perc(0.01, sustain, 0.2), doneAction:2);
		Out.ar(out, Pan2.ar(SinOsc.ar(freq, 0, env), pan))
	}).add;

a = PlazyEnvirN({ arg g=0, h=0, dur=1;
	postf("g: %, h: %, dur: %\n", g, h, dur);

	Pbind(
		\instrument, \help_sinegrain,
		\dur, dur,
		\degree, Pseq([g, g, h, g, h], 2)
	)
});
)
// different variants
(a <> (g: 0, h: 3, dur:0.2)).play; // single stream
(a <> (g: [0, 4], h: [3, -1], dur:0.2)).play; // same durations, two streams
(a <> (g: [0, 4], h: [3, -1], dur: [0.2, 0.3])).play; // different durations, two streams
//Damn, but this function composition business makes this all look very much like functional programming. What is the relationship between CFDG and functors operating on the nested phrases?
