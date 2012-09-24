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
PSProductionSpace : LazyEnvir {

	var <name, <clock, <quant;
	var <awake=true, <group;

	*new { arg , clock;
		^super.new.init(clock);
	}

	*push { arg clock;
		if({ currentEnvironment.isKindOf(this) })
			{ currentEnvironment.clear.pop }; // avoid nesting
		^this.new(clock).push;
	}

	init { arg argClock;
		clock = argClock;
		if(clock.notNil) { this.quant = 1.0 };
	}

	// access and control

	clock_ { arg aClock;
		clock = aClock;
		this.do { arg item; item.clock = aClock };
	}

	quant_ { arg val;
		quant = val;
		this.do { arg item; item.quant = val };
	}

	awake_ { arg flag;
		this.do(_.awake_(flag));
		awake = flag;
	}
	
	doFunctionPerform { arg selector; ^this[selector] }

	printOn { arg stream;
		stream << this.class.name;
		if(envir.isEmpty) { stream << " ()\n"; ^this };
		stream << " ( " << (name ? "") << Char.nl;
		this.keysValuesDo { arg key, item, i;
			stream << "~" << key << " - ";
			stream << if(item.rate === 'audio') { "ar" } {
					if(item.rate === 'control', { "kr" }, { "ir" })
					}
			<< "(" << item.numChannels << ")   " << if(i.even) { "\t\t" } { "\n" };
		};
		stream << "\n)\n"

	}

	postln { Post << this }

	includes { |proxy| ^envir.includes(proxy) }

}
