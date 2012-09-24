PSProductionSystem {
	var <>logger;
	var <ruleMap;
	
	*new{|logger|
		^super.newCopyArgs(logger ?? NullLogger.new).initPSProductionSystem;
	}
	initPSProductionSystem {
		ruleMap = Environment.new;
	}
	makePreTerminal {|name, weightedList|
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		var sneakyInvocationCounter = 0;
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		^Pspawner({ |sp|
			var ruleSymbols, rulePatternList, nextPhrase, nextStream;
			var spawnlogger = this.logger ?? {NullLogger.new};

			sneakyInvocationCounter = sneakyInvocationCounter + 1;
			ruleSymbols = expressions.wchoose(weights);
			spawnlogger.log(tag: \ruleSymbols, msgchunks: ruleSymbols, priority: 1);
			rulePatternList = ruleSymbols.collect({|i|
				ruleMap.at(i) ?? {"terminal '%' not found".format(i).throw;};
			});
			nextPhrase = Pchain(*rulePatternList);
			nextStream = sp.seq(nextPhrase);
			spawnlogger.log(tag: \depth, msgchunks: [sneakyInvocationCounter], priority: 1);
		});
	}
	putRule{|name, pattern|
		ruleMap.put(name, pattern);
	}
}