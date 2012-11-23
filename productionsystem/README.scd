/*************************
 * PS Production System
 *************************
 
Multidimensional time-bound grammars for your pleasure and diversion.
 
 Gotchas
 *************

Event and Rests and Pbinds with constants in the values, per default, embed infinitely often.
That is not what we usually want here.
Pobind and PoRest are convenient classes that embed a Pbind or a Rest JUST ONCE.

PSBranches take a little thinking about.
Since a PSBranch causes an immediate parallelisation, anything in the PSBranch is executed concurrently with whatever comes AFTER the branch.
You are likely to want SOMETHING to come syntactically "after" (and therefore concurrently with) a branch, even if only a rest, so that everything doesn't happen at once. 
Parallel branches have no length of their own.
So that after-thing will determine the duration of the current phrase, and you don't want all the music happening at once. 
*Usually* you don't.

A rule does not start a new context, it simply expands some symbols.
This means that the following are equivalent:

(
var ps = PSProductionSystem.new;
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putAtom(\note, Pobind(\note, 0, \dur, 1));
ps.putRule(\root, \doubleSpeed, \note, \doubleSpeed, \note, \doubleSpeed, \note);
)
and
(
var ps = PSProductionSystem.new;
ps.putOp(\doubleSpeed, POp(\stretch, Affine1(1/2)));
ps.putAtom(\note, Pobind(\note, 0, \dur, 1));
ps.putRule(\part1, \doubleSpeed, \note, \doubleSpeed);
ps.putRule(\part2, \note, \doubleSpeed, \note);
ps.putRule(\root, \part1, \part2);
)

 
 TODO
 *************

 * Should collections be a synonym for PSBranch, by analogy with normal parallel expansion?
 * Stochastic factories, producing Affine transforms (or, more conveniently, POps) to desired specs
 * make POp editable
 	* Refactor POp to use a dict internally, since I end up casting to it all the time anyway.
 * make some examples
   * moombahton, or a samba
   * breakbeat cuts
 * swing.shuffle patterns(Jitlib has examples of clock-sensitive alteration)
 * guis for Ops and PSChoices, maybe even rules.
 * a pattern library for PSProductionSystem
 * accept naked patterns instead of tokens for convenience
 * create a reporter function that will send OSC messages when an Atom is expressed, so that it might be visualised or whatever
	* pump events to some external OSC thing for visualising, perhaps with a PFunc
  	* Note that to get note OFF events this requires hooking in to the EventStreamCleanup/EventTypesWithCleanup infrastructure. NodeWatcher might be able to do this. I Think Pproto has examples of how to do all this.
 * replace Pobind and other ad hoc patterns with real classes, not factories, so that they are not opaque.
 */