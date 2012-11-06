/*
 * OK, the proxyspace stuff is overkill at the moment,
 but I think that I still need to be able to look up things lazily.
 
 Two approaches to rule management:
 1) symbols in a dict
 2) Proxy-space style late interpretation
 
 Virtues of 1, implemented below:
 * straightforward
 * minimal proof-of-concept
 * transparent relationship to classic production grammar
 
 Vices of 1:
 * produces rules that are bound to a particular production system, but whose binding is not obvious
 * have to implement a (minimal) parser
 * how do you get easy repetition, Kleene star style? make parser?
 
 Virtues of 2
 * Pattern DSL (handy for such things as arbitrary nesting and repetition)
 * Easy references to undefined rules
 
 Vices of 2:
 * Tedious and painful debugging of confusing code structures because that is how the oddball world of proxyspace rolls
  
 */

PSProductionSystem {
	var <>logger;
	var <ruleMap;
	var <opMap;
	var <atomMap;
	var <>rootSymbol=\root;
	/* Glossary:
	A Rule is a preterminal symbol.
	Terminal symbols are either Op(erator)s or Atoms, which are Patterns that express actual musical events.
	Later, we might have StackOperations, or whatever you call L-systems brackets, and Kleene stars, and applications
	*/
	
	*new{|logger, ruleMap, opMap, atomMap|
		^super.newCopyArgs(
			logger ?? {NullLogger.new},
			ruleMap ?? {Environment.new},
			opMap ?? {Environment.new},
			atomMap ?? {Environment.new}
		);
	}
	putAtom{|name, pattern|
		atomMap.put(name, pattern);
	}
	putOp{|name, pattern|
		//should we be checking for duplicate symbols here?
		opMap.put(name, pattern);
	}
	putRule {|ruleName ...tokens|
		ruleMap[ruleName] = tokens;
	}
	tokenValueAndType{|name|
		//this throws an error for not found
		var found = case 
			{ ruleMap.includesKey(name) }	{ [ruleMap[name], \rule] }
			{ opMap.includesKey(name) }	{ [opMap[name], \op] }
			{ atomMap.includesKey(name) }	{ [atomMap[name], \atom] };
		found.isNil.if({MissingError("symbol '%' not found".format(name)).throw});
		^found
	}
	at{|name|
		//this returns nil for not found
		^({ ruleMap.at(name) } ?? { opMap.at(name) } ?? { atomMap.at(name) });
	}
	root{
		^this.asPattern([rootSymbol]);
	}
	removeAt{|name|
		ruleMap.removeAt(name);
		opMap.removeAt(name);
		atomMap.removeAt(name);
	}
	asPattern {|symbols, context, depth=0|
		^Pspawner({ |sp|
			this.logger.log(tag: \asPattern, msgchunks: symbols++ [\myspawner, sp.identityHash], priority: 1);
			this.expressWithContext(sp, opStack: context ?? Array.new, nextTokens: symbols, depth: depth+1);
		});
	}
	expressWithContext{|sp, opStack, nextTokens, depth=0|
		//Here is the symbol parsing recursive state-machine.
		//opStack content is applied to all symbols
		var nextPhraseStack = List.new;
		var nextPhraseTokens = List.new;
		var token;
		var nextTokensIterator;
		this.logger.log(tag: \ewc, msgchunks: (opStack++ [\nt] ++ nextTokens ++ [\depth, depth]), priority: 1);
		//To handle algorithmic expansion, we have our incoming symbols as a Stream
		nextTokensIterator = PSIterator(nextTokens);
		token = nextTokensIterator.next;
		{token.notNil}.while({
			//secret bonus feature: you can pass in callables.
			this.logger.log(tag: \token, msgchunks: [\before, token], priority: 1);
			token = token.value;
			this.logger.log(tag: \token, msgchunks: [\after, token], priority: 1);
			case
				{token.isKindOf(PSParen)} {
					//Parenthetical list of tokens that should share a transform stack
					this.logger.log(tag: \paren, msgchunks: (opStack++ [\nt] ++ token.tokens), priority: 1);
					this.expressWithContext(sp, opStack ++ nextPhraseStack, token.tokens, depth: depth+1);
					nextPhraseStack = List.new;
					nextPhraseTokens = List.new;
				}
				{token.isKindOf(PSWlist)} {
					var next;
					// Random choice.
					// choose one from this list.
					this.logger.log(tag: \wlist, msgchunks: ([\ops] ++ opStack++ [\choice] ++ token.weights ++ token.expressions), priority: 1);
					next = token.choose;
					this.logger.log(tag: \wlist, msgchunks: ([\chose] ++ next), priority: 1);
					this.logger.log(tag: \remaining, msgchunks: nextTokens, priority: 1);
					nextTokensIterator = PSIterator(next) ++ nextTokensIterator;
					this.logger.log(tag: \remaining, msgchunks: nextTokens, priority: 1);
				}
				{token.isKindOf(PSBranch)} {
					var branches = Array.new;
					// branch into parallel streams
					this.logger.log(tag: \branch, msgchunks: ([\ops] ++ opStack++ [\branches] ++ token.branches), priority: 1);
					token.branches.do({|branch|
						var branchpatt = this.asPattern(symbols: branch, context:  opStack, depth: depth+1);
						this.logger.log(tag: \branching, msgchunks: (branch), priority: 1);
						branches = branches.add(sp.par(branchpatt));
					});
				}
				{token.isKindOf(PSStar)} {
					// repeat this stream for a while
					this.logger.log(tag: \star, msgchunks: ([\ops] ++ opStack++ [\star] ++ token), priority: 1);
					nextTokensIterator = (token.iterator) ++ nextTokensIterator;
				}
				{true} {
					var tokencontent, type;
					//default case.
					//standard symbol token, to be expanded.
					//accumulate Ops until we hit an event then express it.
					this.logger.log(tag: \sym, msgchunks: [token], priority: 1);
					# tokencontent, type = this.tokenValueAndType(token);
					//secret bonus feature: you can pass in callables.
					this.logger.log(tag: \tokencontent, msgchunks: [\before, tokencontent], priority: 1);
					tokencontent = tokencontent.value;
					this.logger.log(tag: \tokencontent, msgchunks: [\after, tokencontent], priority: 1);
					type.switch(
						\op, {
							//accumulate ops
							nextPhraseStack.add(tokencontent);
							nextPhraseTokens.add(token);
							this.logger.log(tag: \accumulation, msgchunks: [\pt] ++ nextPhraseStack, priority: 1);
							this.logger.log(tag: \accumulation, msgchunks: [\nt] ++ nextPhraseTokens, priority: 1);
						},
						\atom, {
							//apply operators to event. or rule.
							//note that Pchain applies RTL.
							var squashedPat, wholecontext;
							nextPhraseStack.add(tokencontent);
							nextPhraseTokens.add(token);
							this.logger.log(tag: \application, msgchunks: [\pt] ++ nextPhraseStack, priority: 1);
							this.logger.log(tag: \application, msgchunks: [\nt] ++ nextPhraseTokens, priority: 1);
							wholecontext = (opStack ++ nextPhraseStack).asArray;
							this.logger.log(tag: \application, msgchunks: [\ct] ++ nextPhraseTokens, priority: 1);
							//this explodes things:
							//wholecontext = [Pset(\depth, depth)] ++ wholecontext;
							squashedPat = Pchain(*wholecontext);
							sp.seq(squashedPat);
							nextPhraseStack = List.new;
							nextPhraseTokens = List.new;
						},
						\rule, {
							// A rule. Expand it and continue.
							// Do we want rule application to implicitly group ops? it does not ATM.
							// Use PSParen if you want that behaviour.
							this.logger.log(tag: \expansion, msgchunks: tokencontent, priority: 1);
							this.logger.log(tag: \remaining, msgchunks: nextTokens, priority: 1);
							nextTokensIterator = PSIterator(tokencontent) ++ nextTokensIterator;
							this.logger.log(tag: \remaining, msgchunks: nextTokens, priority: 1);
							
						}
					);
				};
			token = nextTokensIterator.next;
			this.logger.log(tag: \remaining, msgchunks: nextTokens, priority: 1);
		});
		^sp;
	}

	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << "rules: [";
		ruleMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << "operators: [";
		opMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << "atoms: [";
		atomMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << ")";
	}
	//delegate pattern-like business to the root rule (called \root per default)
	asStream { ^Routine({ arg inval; this.embedInStream(inval) }) }
	embedInStream{|inval|
		^this.root.embedInStream(inval);
	}
}
//// These are all just processing tokens.
// They are not designed to have general use outside of PSProductionSystem state machines.

PSWlist {
	//Choose a random sub-option at this point.
	var <weights;
	var <expressions;
	*new {|...weightedList|
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		^super.newCopyArgs(weights, expressions);
	}
	choose {
		^expressions.wchoose(weights) ?? {Array.new};
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << "[";
		weights.size.do({|i|
			stream << weights[i] << ": " << expressions[i] << "; "
		});
		stream << "], ";
		stream << ")";
	}
}
PSParen {
	//we use this to indicate that the preceeding transforms should be applied to ALL the contents of this PSParen
	var <tokens;
	*new {|...tokens|
		^super.newCopyArgs(tokens)
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString;
		stream << ")";
	}
}
PSBranch {
	//we use this to indicate that the list of branches here should be executed in parallel.
	var <branches;
	*new {|...branches|
		^super.newCopyArgs(branches)
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << branches.asCompileString;
		stream << ")";
	}
}
//Kleene stars and things inspired by them. Syntactic sugar to handle repetition without duplicating things manually.
PSStar {
	//A Kleene star, repeating something forever.
	var <tokens;
	*new {|...tokens|
		^super.newCopyArgs(tokens);
	}
	iterator {
		^Routine({
			loop {
				tokens.do(_.yield);
			}
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString << "*";
		stream << ")";
	}
}
PSStarN : PSStar {
	//A Kleene star, repeating something N times.
	var <n;
	*new {|n ...tokens|
		^super.newCopyArgs(tokens, n);
	}
	iterator {
		^Routine({
			n.do({
				tokens.do(_.yield);
			})
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString << "{" << n <<"}";
		stream << ")";
	}
}
PSStarRange : PSStar {
	//A Kleene star, accepting limits.
	// To be well-defined this must have finite limits
	var <min, <max;
	*new {|min=0, max=4 ...tokens|
		^super.newCopyArgs(tokens, min, max);
	}
	iterator {
		^Routine({
			rrand(min,max).do({
				tokens.do(_.yield);
			});
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString << "{" << min << ", " << max <<"}";
		stream << ")";
	}
}
PSStarGeom : PSStar {
	//A Kleene star, with geometric (i.e. unbounded) distribution, accepting a mean.
	var <mean, <chanceofRepeat;
	*new {|mean ...tokens|
		^super.newCopyArgs(tokens, mean, 1-(mean.reciprocal));
	}
	iterator {
		^Routine({
			({chanceofRepeat.coin}).while({
				tokens.do(_.yield);
			});
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString << "*{mean: " << mean <<"}";
		stream << ")";
	}
}
PSStarGen : PSStar {
	//A generalised Kleene star, accepting an arbitrary distribution of repetitions.
	var <rng;
	*new {|rng ...tokens|
		^super.newCopyArgs(tokens, rng);
	}
	value {
		^tokens.dup(rng.value)
	}
	iterator {
		^Routine({
			rng.value.do({
				tokens.yield;
			});
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << tokens.asCompileString << "*{rng: " << rng.asCompileString <<"}";
		stream << ")";
	}
}