PSProductionRuleSet {
    var <rules;
    var <weights;
    var <cdfs;
	var <preterminals;
	var <>defaultStartRule;
    *new{
        ^super.new.initPSProductionRuleSet;
    }
    initPSProductionRuleSet {
        rules = ();
        weights = ();
        cdfs = ();
		preterminals = IdentitySet[];
    }
	add {|key, weight=1, expression|
		var ruleset, weightset, cdf;
		key = key.asSymbol;
		ruleset = (rules[key] ?? Array.new).add(expression);
		weightset = (weights[key] ?? Array.new).add(weight);
		cdf = ((weightset)/(weightset.sum)).integrate;
		//make sure our cdf doesn't panic because of float rounding:
		cdf[cdf.size-1] = inf;
		rules[key] = ruleset;
		weights[key] = weightset;
		cdfs[key] = cdf;
		preterminals.add(key);
	}
	next {|key, omega|
		//omega is the lookup variable
		^(rules[key])[cdfs[key].indexOfGreaterThan(omega ?? 1.0.rand)];
	}
	isPreterminal{|symbol|
		preterminals.findMatch(symbol).notNil.if({^true}, {^false});
	}
	isTerminal{|symbol|
		^this.isPreterminal(symbol).not;
	}
	asStream{|startRule|
		//we take a startRule param here. But asStream doesn't normally supply this
		//so we fall back to some defaults.
		startRule = startRule ?? defaultStartRule;
		startRule = startRule ?? {preterminals.choose;};
		^Routine({
			this.next(startRule).do({|currentSymbol|
				this.isTerminal(currentSymbol).if(
					{currentSymbol.yield;},
					{this.asStream(currentSymbol).embedInStream;}
				);
			});
		});
	}
}