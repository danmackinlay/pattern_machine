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
Since a PSBranch causes an immediate parallelisation, anything in the PRSBranch is executed with whatever comes AFTER the branch.
You are likely to want SOMETHING to come after.
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

 * Use my lovely POp class's ability to collapse
 * Should collections be a synonym for PSBranch?
 * Stochastic factories, producing Affine transforms (or, more conveniently, POps) to desired specs
 * make POp editable
 	* Refactor POp to use a dict internally, since I end up casting to it all the time anyway.
 * pump events to some external OSC thing for visualising, perhaps with a PFunc
 * make moombahton
 * a pattern library for PSProductionSystem
 * accept naked patterns instead of tokens for convenience
 * create a reporter function that will send OSC messages when an Atom is expressed, so that it might be visualised or whatever
 * replace Pobind and other ad hoc patterns with real classes not factories so that they are not opaque.
 */