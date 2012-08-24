PSProductionPlayer {
	var symbolStream;
	var coding;
    *new{|symbolStream, coding|
        ^super.newCopyArgs(symbolStream.asStream, coding);
    }
    asStream{
		//Should i not rather implement embedInStream as per http://doc.sccode.org/Tutorials/A-Practical-Guide/PG_Ref01_Pattern_Internals.html
		^Routine({
	    	var nextSymbol;
			var context;
			var contextStack = contextStack ? PSEventOperator.new;
		
			while ({
				nextSymbol = symbolStream.next;
				nextSymbol.notNil;
			}, {
				//stack operations until we find an atom we can yield.
				coding.isAtom(nextSymbol).if({
					contextStack.applyTo(coding[nextSymbol]).yield;
				}, {
					contextStack = contextStack.applyTo(coding[nextSymbol]);
				});
			});
			nil;
		});
    }
}