PSProductionCoding : IdentityDictionary {
	var <atoms;
	var <operators;
	*new{|...args|
		^super.new(*args).initPSProductionCoding;
	}
	isAtom{|symbol|
		^atoms.findMatch(symbol).notNil;
	}
	isOperator{|symbol|
		^operators.findMatch(symbol).notNil;
	}
	initPSProductionCoding{
		atoms = IdentitySet.new;
		operators = IdentitySet.new;
	}
	put{|k,v|
		//Duck-type test for PSOperators
		v.respondsTo(\applyTo).if(
			{operators.add(k)},
			{atoms.add(k)}
		);
		^super.put(k, v);
	}
}
PSn {
	/* The Kleene Star, just a little more general.
	This guy quantifies the idea of repeating squentially (as opposed to in parallel, which is governed by Arrays)
	Can I replace these with Pn and Ppar?
	*/
	var <expression;
	var <ref;
	*new{|expression, rep=inf|
		^newCopyArgs(expression, rep);
	}
}