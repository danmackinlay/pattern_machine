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
			atomMap ?? {Environment.new},
		);
	}
	putRule {|ruleName, weightedList|
		var rule;
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		this.logger.log(tag: \weights, msgchunks: weights, priority: 1);
		this.logger.log(tag: \expressions, msgchunks: expressions, priority: 1);
		
		rule = Pspawner({ |sp|
			var ruleTokens, nextPhrase, nextStream;
			var spawnlogger = this.logger ?? {NullLogger.new};
			spawnlogger.log(tag: \rule, msgchunks: [ruleName], priority: 1);

			ruleTokens = expressions.wchoose(weights);
			spawnlogger.log(tag: \ruleTokens, msgchunks: ruleTokens, priority: 1);
			this.expressWithContext(sp, List.new, ruleTokens);
		});
		ruleMap[ruleName] = rule;
		^rule;
	}
	expressWithContext{|sp, opStack, nextTokens|
		//Here is the symbol parsing state-machine.
		//opStack content is applied to all symbols
		var nextPhrase, nextStream;
		nextPhrase = List.new;
		nextTokens.do({|token|
			case
				{token.isKindOf(PSParen)} {
					//Parenthetical list of tokens that should share a transform stack
					this.logger.log(tag: \paren, msgchunks: token.tokens, priority: 1);
					this.expressWithContext(sp, opStack ++ nextPhrase, token.tokens);
					nextPhrase = List.new;
				}
				{true} {
					var rule, type;
					//standard symbol token.
					//accumulate Ops until we hit an event then express it.
					# rule, type = this.patternTypeBySymbol(token);
					nextPhrase.add(rule);
					this.logger.log(tag: \sym, msgchunks: [token], priority: 1);
					((type==\rule)||(type==\event)).if({
						//apply operators to event. or rule.
						//note that Pchain applies RTL and L-systems LTR, so think carefully.
						//Do we really want rule application to implicitly group ops?
						this.logger.log(tag: \application, msgchunks: nextPhrase.reverse, priority: 1);
						nextStream = sp.seq(Pchain(*((opStack ++ nextPhrase).asArray)));
						nextPhrase = List.new;
					});
					
				};
		});
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
	patternTypeBySymbol{|name|
		//this throws an error for not found
		var found = case 
			{ ruleMap.includesKey(name) }	{ [ruleMap[name], \rule] }
			{ opMap.includesKey(name) }	{ [opMap[name], \op] }
			{ atomMap.includesKey(name) }	{ [atomMap[name], \event] };
		found.isNil.if({MissingError("symbol '%' not found".format(name)).throw});
		^found
	}
	at{|name|
		//this automagically returns nil for not found
		^({ ruleMap.at(name) } ?? { opMap.at(name) } ?? { atomMap.at(name) });
	}
	root{
		^this.ruleMap[rootSymbol]
	}
	removeAt{|name|
		ruleMap.removeAt(name);
		opMap.removeAt(name);
		atomMap.removeAt(name);
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
PSParen {
	//we use this to indicate that the preceeding transforms should be applied to ALL the contents of this PSParen
	var <tokens;
	*new {|...tokens|
		^super.newCopyArgs(tokens)
	}
}
PSBranch {
	//we use this to indicate that the list of branches here should be executed in parallel.
	//not yet implemented.
	var <branches;
	*new {|...branches|
		NotYetImplementedError("Branching doesn't work yet").throw;
		^super.newCopyArgs(branches)
	}
}