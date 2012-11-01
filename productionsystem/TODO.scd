/*************
 * TODO
 *************

 * Create a Function subclass, AffineTransform, that automatically collapses
   simple transforms and also prints a better diagnostic with printOn
     * and test that if composes fine with normal functions
 * Allow stacks of transforms, and transform stack push/operations (brackets, say)
   * this is implicit at the moment, actually, since transforms are applied whenever one hits an Event or Rule, then the stack is cleared.
   	 * FunctionList looks like it's designed for precisely this.
 * Stochastic factories, producing Affine transforms (or, more conveniently, POps) to desired specs
 * Refactor POp to us a dict internally, since I end up casting to it all the time anyway.
 */