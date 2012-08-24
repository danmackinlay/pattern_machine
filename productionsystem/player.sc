PSProductionPlayer {
	var symbolStream;
	var coding;
    *new{|symbolStream, coding|
        ^super.newCopyArgs(symbolStream.asStream, coding);
    }
    asStream{
		^Routine({
	    	var nextSymbol;
			var context;
			var contextStack = Array.new;
			var log = FileLogger.global;
		
			while ({
				nextSymbol = symbolStream.next;
				nextSymbol.notNil;
			}, {
				//stack operations until we find an atom we can yield.
				contextStack = contextStack.add(coding[nextSymbol]);
				coding.isAtom(nextSymbol).if({
					(contextStack.reduce({|left,right| left.applyTo(right)})).yield;
					contextStack = Array.new;
				})
			});
			nil;
		});
    }
}