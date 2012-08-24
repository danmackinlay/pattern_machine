//Clone ddw's Ppatrewrite. it is close to what I want, but does too much.
//N.B. FilterPattern ONLY adds a "pattern" instance var.
/*
PSpatRewrite : FilterPattern {
	var	<>levelPattern, <>rules, <>defaultRule,
		<>autoStreamArrays = true,
		<>reuseLevelResults = false;

	*new { |pattern, levelPattern, rules, defaultRule,
		autoStreamArrays = true, reuseLevelResults = false|
		^super.new(pattern).levelPattern_(levelPattern)
			.rules_(rules)
			.defaultRule_(defaultRule ?? { nil -> { |in| in } })
			.autoStreamArrays_(autoStreamArrays).reuseLevelResults_(reuseLevelResults)
	}

	embedInStream { |inval|
		var	levelStream = levelPattern.asStream,
			level, outputs = List.new;
		while { (level = levelStream.next(inval)).notNil } {
			inval = this.recurse(inval, pattern.asStream, level, outputs);
		};
		^inval
	}

	recurse { |inval, inStream, level, outputs|
		var	rule;
		if(reuseLevelResults and: { outputs[level].notNil }) {
			^Pseq(outputs[level], 1).embedInStream(inval)
		} {
			// mondo sucko that I have to hack into the List
			outputs.array = outputs.array.extend(max(level+1, outputs.size));
			outputs[level] = List.new;
			if(level > 0) {
				r { |inval| this.recurse(inval, inStream, level-1, outputs) }
				.do { |item|
					case
					// matched a rule, use it
					{ (rule = rules.detect { |assn| assn.key.matchItem(item) }).notNil }
						{ inval = this.rewrite(item, rule, inval, level, outputs) }
					// matched the default rule
					{ defaultRule.key.matchItem(item) }
						{ inval = this.rewrite(item, defaultRule, inval, level, outputs) }
					// no match, just spit out the item unchanged
					{ outputs[level].add(item); inval = item.embedInStream(inval) };
				};
			} {
				inval = inStream.collect { |item|
					outputs[level].add(item);
					item
				}.embedInStream(inval);
			};
		};
		^inval
	}

	rewrite { |item, rule, inval, level, outputs|
		var	result = rule.value.value(item, level, inval);
		if(autoStreamArrays and: { result.isSequenceableCollection }) {
			result = Pseq(result, 1);
		};
		^result.asStream.collect { |item| outputs[level].add(item); item }.embedInStream(inval);
	}
}
*/
//Clone standard library's Pwrand pattern, which does what I want but has an unpleasant syntax.
//NB ListPattern ONLY adds list and repeats instance vars.
/*
PSwrand : ListPattern {
	var <>weights;
	*new { arg list, weights, repeats=1;
		^super.new(list, repeats).weights_(weights)
	}
	embedInStream {  arg inval;
		var item, wVal;
		var wStr = weights.asStream;
		repeats.value(inval).do({ arg i;
			wVal = wStr.next(inval);
			if(wVal.isNil) { ^inval };
			item = list.at(wVal.windex);
			inval = item.embedInStream(inval);
		});
		^inval
	}
	storeArgs { ^[ list, weights, repeats ] }
}
*/