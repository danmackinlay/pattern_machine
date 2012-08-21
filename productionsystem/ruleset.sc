PSProductionRuleSet {
    var <rules;
    var <weights;
    var <normWeights;
    *new{
        ^super.new.initPSProductionRuleSet;
    }
    initPSProductionRuleSet {
        rules = ();
        weights = ();
        normWeights = ();
    }
	add {|key, weight=1, expression|
		rules[key] = (rules[key] ?? Array.new).add(expression);
		weights[key] = (weights[key] ?? Array.new).add(weight);
		normWeights[key] = (weights[key])/(weights[key].sum);
	}
	next {|key|
		^(rules[key]).wchoose(normWeights[key]);
	}
	seed{|key|
		/*yield symbols until it is over.*/
		/*actually, this probably needs to happen in a spawner*/
	}
}