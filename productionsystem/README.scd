/*************************
 * PS Production System
 *************************
 
Multidimensional time-bound grammars for your pleasure and diversion.
 
 Gotchas
 *************

Event and Rests and Pbinds with constants in the values, per default, embed infinitely often.
That is not what we usually want here.
Pobind and PoRest are convenient classes that embed a Pbind or a Rest JUST ONCE.

 
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
 */