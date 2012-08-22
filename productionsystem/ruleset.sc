PSProductionRuleSet {
    var <rules;
    var <weights;
    var <cdfs;
    *new{
        ^super.new.initPSProductionRuleSet;
    }
    initPSProductionRuleSet {
        rules = ();
        weights = ();
        cdfs = ();
    }
	add {|key, weight=1, expression|
		var ruleset, weightset, cdf;
		ruleset = (rules[key] ?? Array.new).add(expression);
		weightset = (weights[key] ?? Array.new).add(weight);
		cdf = ((weightset)/(weightset.sum)).integrate;
		//make sure our cdf doesn't panic because of float rounding:
		cdf[cdf.size-1] = inf;
		rules[key] = ruleset;
		weights[key] = weightset;
		cdfs[key] = cdf;
	}
	next {|key, omega|
		//omega is the lookup variable
		^(rules[key])[cdfs[key].indexOfGreaterThan(omega ?? 1.0.rand)];
	}
	seed{|key|
		/*yield symbols until it is over.*/
		/*actually, this probably needs to happen in a spawner*/
	}
}