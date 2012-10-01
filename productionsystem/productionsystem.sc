/*
 * OK, the proxyspace stuff is overkill at the moment,
 but I think that I still need to be able to look up things lazily. 
 This could happen in the makePreTerminal thing, in which case it would need to output
 rules with the dynamic lookup thing baked in.
 
 Two approaches to rule management:
 1) symbols in a dict
 2) Proxy-space style late interpretation
 
 Virtues of 1, implemented below:
 * straightforward
 * minimal proof-of-concept
 
 Vices of 1:
 * produces rules that are bound a a particular production system, but whose binding is not obvious
 * have to implement a (minimal) parser
 * how do you get easy repetition, Kleene star style? make parser
 
 Virtues of 2
 * Pattern DSL (handy for such things as arbitrary nesting and repetition)
 * Easy references to undefined rules
 
 Vices of 2:
 * Silly debugging and reference business because that is how proxyspace rolls
 
 */

PSProductionSystem {
	var <>logger;
	var <ruleMap;
	
	*new{|logger, ruleMap|
		^super.newCopyArgs(
			logger ?? {NullLogger.new},
			ruleMap ?? {Environment.new},
		);
	}
	putPreTerminal {|name, weightedList|
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
				ruleMap.at(i) ?? {"symbol '%' not found".format(i).throw;};
			});
			nextPhrase = Pchain(*rulePatternList);
			nextStream = sp.seq(nextPhrase);
		});
		ruleMap[name] = rule;
		^rule;
	}
	putTerminal{|name, pattern|
		ruleMap.put(name, pattern);
		//For symmetry with putPreTerminal
		^pattern;
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		ruleMap.associationsDo({|i|
			stream << i
		});
		stream << ")";
	}
}
