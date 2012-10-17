/*************
 * TODO
 *************

 * Create a Function subclass, AffineTransform, that automatically collapses
   simple transforms and also prints a better diagnostic with printOn
 * Allow stacks of transforms, and transform stack push/operations (brackets, say)
   * this is implicit at the moment, actually, since transforms are applied whenever one hits an Event or Rule, then the stack is cleared.
 * Allow branches
   * I think Doing This Properly this would require implementing a method that returned an ad-hoc collection of tokens as a Pattern (probably a PSpawner). Although it would be trivial if we only supported branching into Rules.
 */