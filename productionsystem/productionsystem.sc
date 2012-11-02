/*
 * OK, the proxyspace stuff is overkill at the moment,
 but I think that I still need to be able to look up things lazily. 
 This could happen in the makeRule thing, in which case it would need to output
 rules with the dynamic lookup thing baked in.
 
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
 * Silly debugging and reference business because that is how proxyspace rolls
 
 maybe this should mirror the interface of a Dictionary a little more closely?
 
 */

PSProductionSystem {
	var <>logger;
	var <ruleMap;
	var <opMap;
	var <atomMap;
	var <>trace;
	var <>rootSymbol=\root;
	/* Glossary:
	A Rule is a preterminal symbol.
	Terminal symbols are either Op(erator)s or Atoms, which are Patterns that express actual musical events.
	Later, we might have StackOperations, or whatever you call L-systems brackets, and Kleene stars, and applications
	*/
	
	*new{|logger, ruleMap, opMap, atomMap, trace=false|
		^super.newCopyArgs(
			logger ?? {NullLogger.new},
			ruleMap ?? {Environment.new},
			opMap ?? {Environment.new},
			atomMap ?? {Environment.new},
			trace
		);
	}
	putAtom{|name, pattern|
		atomMap.put(name, pattern);
		//For symmetry with putRule, we return the pattern
		^pattern;
	}
	putOp{|name, pattern|
		//should we be checking for duplicate symbols here?
		opMap.put(name, pattern);
		//For symmetry with putRule, we return the pattern
		^pattern;
	}
	tokenValueAndType{|name|
		//this throws an error for not found
		var found = case 
			{ ruleMap.includesKey(name) }	{ [ruleMap[name], \rule] }
			{ opMap.includesKey(name) }	{ [opMap[name], \op] }
			{ atomMap.includesKey(name) }	{ [atomMap[name], \event] };
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
	putRule {|ruleName, tokens|
		ruleMap[ruleName] = tokens;
		^this.asPattern(tokens);
	}
	asPattern {|symbols, context, depth=0|
		^Pspawner({ |sp|
			this.logger.log(tag: \asPattern, msgchunks: symbols++ [\myspawner, sp.identityHash], priority: 1);
			this.expressWithContext(sp, opStack: context ?? Array.new, nextTokens: symbols, depth: depth+1);
		});
	}
	expressWithContext{|sp, opStack, nextTokens, depth=0|
		//Here is the symbol parsing state-machine.
		//opStack content is applied to all symbols
		var nextPhraseStack = List.new;
		var nextPhraseTokens = List.new;
		this.logger.log(tag: \ewc, msgchunks: (opStack++ [\nt] ++ nextTokens ++ [\depth, depth]), priority: 1);
		nextTokens.do({|token|
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
					this.logger.log(tag: \wlist, msgchunks: ([\ops] ++ opStack++ [\choise] ++ token.weights ++ token.expressions), priority: 1);
					next = token.choose;
					this.logger.log(tag: \wlist, msgchunks: ([\chose] ++ next), priority: 1);
					this.expressWithContext(sp, opStack ++ nextPhraseStack, next, depth: depth+1);
					nextPhraseStack = List.new;
					nextPhraseTokens = List.new;
				}
				{token.isKindOf(PSBranch)} {
					var branches = Array.new;
					// branch into parallel streams
					this.logger.log(tag: \branch, msgchunks: ([\ops] ++ opStack++ [\branches] ++ token.branches), priority: 1);
					token.branches.do({|nextTokens|
						var branchpatt = this.asPattern(symbols: nextTokens, context:  opStack, depth: depth+1);
						this.logger.log(tag: \branching, msgchunks: (nextTokens), priority: 1);
						branches = branches.add(sp.par(
							trace.if({Ptrace(branchpatt, prefix: \depth ++ depth)}, {branchpatt});
						));
					});
					nextPhraseStack = List.new;
					nextPhraseTokens = List.new;
				}
				{token.isKindOf(PSStar)} {
					// repeat this stream for a while
					this.logger.log(tag: \star, msgchunks: ([\ops] ++ opStack++ [\star] ++ token), priority: 1);
					token.iterator.do({|next, i|
						this.logger.log(tag: \starring, msgchunks: [i]++next, priority: 1);
						this.expressWithContext(sp, opStack ++ nextPhraseStack, next, depth: depth);
					});
					nextPhraseStack = List.new;
					nextPhraseTokens = List.new;
				}
				{true} {
					var patt, type;
					//default case.
					//standard symbol token, to be expanded.
					//accumulate Ops until we hit an event then express it.
					this.logger.log(tag: \sym, msgchunks: [token], priority: 1);
					# patt, type = this.tokenValueAndType(token);
					//secret bonus feature: you can pass in callables.
					this.logger.log(tag: \patt, msgchunks: [\before, patt], priority: 1);
					patt = patt.value;
					this.logger.log(tag: \patt, msgchunks: [\after, patt], priority: 1);
					type.switch(
						\op, {
							//accumulate ops
							nextPhraseStack.add(patt);
							nextPhraseTokens.add(token);
							this.logger.log(tag: \accumulation, msgchunks: [\pt] ++ nextPhraseStack, priority: 1);
							this.logger.log(tag: \accumulation, msgchunks: [\nt] ++ nextPhraseTokens, priority: 1);
						},
						\event, {
							//apply operators to event. or rule.
							//note that Pchain applies RTL, and L-systems LTR, so think carefully.
							var squashedPat, wholecontext, nextbit;
							nextPhraseStack.add(patt);
							nextPhraseTokens.add(token);
							this.logger.log(tag: \application, msgchunks: [\pt] ++ nextPhraseStack, priority: 1);
							this.logger.log(tag: \application, msgchunks: [\nt] ++ nextPhraseTokens, priority: 1);
							wholecontext = (opStack ++ nextPhraseStack).asArray;
							this.logger.log(tag: \application, msgchunks: [\ct] ++ nextPhraseTokens, priority: 1);
							//wholecontext = [Pset(\depth, depth)] ++ wholecontext;
							squashedPat = Pchain(*wholecontext);
							trace.if({Ptrace(squashedPat, prefix: \depth ++ depth)});
							nextbit = [sp.seq(squashedPat)];
							nextPhraseStack = List.new;
							nextPhraseTokens = List.new;
						},
						\rule, {
							// A rule. Expand it and recurse.
							// Do we want rule application to implicitly group ops? it does ATM.
							this.logger.log(tag: \expansion, msgchunks: patt, priority: 1);
							this.expressWithContext(sp, opStack ++ nextPhraseStack, patt, depth: depth+1);
							nextPhraseStack = List.new;
							nextPhraseTokens = List.new;
						}
					);
				};
		});
		^sp;
	}

	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		stream << "preterminals: [";
		ruleMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << "operators: [";
		opMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << "events:";
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
}
PSParen {
	//we use this to indicate that the preceeding transforms should be applied to ALL the contents of this PSParen
	var <tokens;
	*new {|...tokens|
		^super.newCopyArgs(tokens)
	}
}
PSBranch {
	//we use this to indicate that the list of branches here should be executed in parallel.
	var <branches;
	*new {|...branches|
		^super.newCopyArgs(branches)
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
				tokens.yield;
			}
		});
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
				tokens.yield;
			})
		});
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
				tokens.yield;
			});
		});
	}
}
PSStarGeom : PSStar {
	//A Kleene star, with geometric (i.e. unbounded) distribution, accepting a mean.
	//
	var <chanceofRepeat;
	*new {|mean ...tokens|
		^super.newCopyArgs(tokens, 1-(mean.reciprocal));
	}
	iterator {
		^Routine({
			({chanceofRepeat.coin}).while({
				tokens.yield
			});
		});
	}
}
PSStarGen : PSStar {
	//A generalised Kleene star, accepting an arbitray distribution of repetitions.
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
}