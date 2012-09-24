/*
 * OK, the proxyspace stuff is overkill at the moment, but I think that I still need to be able to look up things lazily. this could haooen in the makePreTerminal thing.
 */
PSProductionSystem {
	var <>logger;
	var <ruleMap;
	
	*new{|logger, ruleMap|
		^super.newCopyArgs(
			logger ?? {NullLogger.new},
			ruleMap ?? {Environment.new},
		).initPSProductionSystem;
	}
	initPSProductionSystem {
		//nothing, anymore
	}
	putPreTerminal {|name, weightedList|
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		ruleMap[name] = Pspawner({ |sp|
			var ruleSymbols, rulePatternList, nextPhrase, nextStream;
			var spawnlogger = this.logger ?? {NullLogger.new};

			ruleSymbols = expressions.wchoose(weights);
			spawnlogger.log(tag: \ruleSymbols, msgchunks: ruleSymbols, priority: 1);
			rulePatternList = ruleSymbols.collect({|i|
				ruleMap.at(i) ?? {"terminal '%' not found".format(i).throw;};
			});
			nextPhrase = Pchain(*rulePatternList);
			nextStream = sp.seq(nextPhrase);
		});
	}
	put{|name, pattern|
		ruleMap.put(name, pattern);
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" ;
		ruleMap.associationsDo({|i|
			stream << i
		});
		stream << ")";
	}
}
