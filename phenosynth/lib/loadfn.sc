/* a Utility function serving two purposes
1. it allows us to transparently pass through actual functions, but load
	other things from the Library
2. to force a test for missing library names, or it's hard to track what
	went wrong. (Because nil is callable(!))
This could alternatively extend Library.
*/
LoadLibraryFunction {
	*new {|nameOrFunction|
		var candidate;
		nameOrFunction.isFunction.if(
			{^nameOrFunction},
			{
				candidate = Library.atList(nameOrFunction);
				candidate.isNil.if({
					("Nothing found at %".format(nameOrFunction.cs)).throw;
				});
				candidate.isFunction.not.if({
					("Non-function found at % (%)".format(
						nameOrFunction.cs, candidate.cs)
				).throw;
				});
				^candidate;
			}
		);
	}
}