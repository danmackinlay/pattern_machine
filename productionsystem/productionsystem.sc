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
	var <eventMap;
	/* Glossary:
	A Rule is a preterminal symbol.
	Terminal symbols are either Op(erator)s or Events.
	Later, we might have StackOperations, or whatever you call L-systems brackets
	*/
	
	*new{|logger, ruleMap, opMap, eventMap|
		^super.newCopyArgs(
			logger ?? {NullLogger.new},
			ruleMap ?? {Environment.new},
			opMap ?? {Environment.new},
			eventMap ?? {Environment.new},
		);
	}
	putRule {|name, weightedList|
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
			var ruleSymbols, rulePatternList, nextPhrase, nextStream;
			var spawnlogger = this.logger ?? {NullLogger.new};
			[\check, name].postln;

			ruleSymbols = expressions.wchoose(weights);
			[\ruleSymbols, ruleSymbols].postln;
			spawnlogger.log(tag: \ruleSymbols, msgchunks: ruleSymbols, priority: 1);
			rulePatternList = ruleSymbols.collect({|i|
				var ruleType;
				ruleType = this.patternTypeBySymbol(i) ?? {"symbol '%' not found".format(i).throw;};
				ruleType[0];
			});
			///this assumes that all rules are 
			nextPhrase = Pchain(*rulePatternList);
			nextStream = sp.seq(nextPhrase);
		});
		ruleMap[name] = rule;
		^rule;
	}
	putEvent{|name, pattern|
		eventMap.put(name, pattern);
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
		//this automagically returns nil for not found
		^case 
			{ ruleMap.includesKey(name) }	{ [ruleMap[name], \rule] }
			{ opMap.includesKey(name) }	{ [opMap[name], \op] }
			{ eventMap.includesKey(name) }	{ [eventMap[name], \event] };
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
		eventMap.associationsDo({|i|
			stream << i << ", "
		});
		stream << "], ";
		stream << ")";
	}
}
