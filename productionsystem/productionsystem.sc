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
	var <allStreams;
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
			Array.new
		);
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
		//this returns nil for not found
		^({ ruleMap.at(name) } ?? { opMap.at(name) } ?? { atomMap.at(name) });
	}
	root{
		^this.asPattern([rootSymbol]);
	}
	removeAt{|name|
		ruleMap.removeAt(name);
		opMap.removeAt(name);
		atomMap.removeAt(name);
	}
	putRule {|ruleName, tokens|
		ruleMap[ruleName] = tokens;
		^this.asPattern(tokens);
	}
	asPattern {|symbols, context, depth=0|
		^Pspawner({ |sp|
			this.logger.log(tag: \asPattern, msgchunks: symbols++ [\myspawner, sp.identityHash], priority: 1);
			this.expressWithContext(sp, context ?? Array.new, symbols, depth: depth+1);
		});
	}
	expressWithContext{|sp, opStack, nextTokens, depth=0|
		//Here is the symbol parsing state-machine.
		//opStack content is applied to all symbols
		var nextPhrase = Array.new;
		var nextStreams = Array.new;
		this.logger.log(tag: \ewc, msgchunks: (opStack++ [\nt] ++ nextTokens ++ [\depth, depth]), priority: 1);
		nextTokens.do({|token|
			case
				{token.isKindOf(PSParen)} {
					//Parenthetical list of tokens that should share a transform stack
					this.logger.log(tag: \paren, msgchunks: (opStack++ [\nt] ++ token.tokens), priority: 1);
					this.expressWithContext(sp, opStack ++ nextPhrase, token.tokens, depth: depth+1);
					nextPhrase = List.new;
				}
				{token.isKindOf(PSWlist)} {
					var next;
					// Random choice.
					// choose one from this list.
					this.logger.log(tag: \wlist, msgchunks: ([\ops] ++ opStack++ [\choise] ++ token.weights ++ token.expressions), priority: 1);
					next = token.choose;
					this.logger.log(tag: \wlist, msgchunks: ([\chose] ++ next), priority: 1);
					this.expressWithContext(sp, opStack ++ nextPhrase, next, depth: depth+1);
					nextPhrase = List.new;
				}
				{token.isKindOf(PSBranch)} {
					var branches;
					// branch into parallel streams
					this.logger.log(tag: \branch, msgchunks: ([\ops] ++ opStack++ [\branches] ++ token.branches), priority: 1);
					branches = token.branches.collect({|nextTokens|
						this.logger.log(tag: \branching, msgchunks: (nextTokens), priority: 1);
						sp.par(Pspawner({|parsp|
							this.logger.log(tag: \branched, msgchunks: ([\ops] ++ opStack++ [\branch] ++ nextTokens ++ [\myspawner, parsp.identityHash]), priority: 1);
							//this.expressWithContext(parsp, opStack.deepCopy, nextTokens, depth: depth+1);
							this.expressWithContext(parsp, [], nextTokens, depth: depth+1);
							//parsp.seq(Ptrace(Pfin(1, Pbind(\note, depth))));
						}));
					});
					nextStreams = nextStreams ++ branches;
					allStreams = allStreams ++ branches;
					this.logger.log(tag: \okgohomenow, msgchunks: nextStreams, priority: 1);
					nextPhrase = List.new;
				}
				{true} {
					var patt, type;
					//default case.
					//standard symbol token, to be expanded.
					//accumulate Ops until we hit an event then express it.
					# patt, type = this.patternTypeBySymbol(token);
					this.logger.log(tag: \sym, msgchunks: [token], priority: 1);
					type.switch(
						\op, {
							//accumulate ops
							nextPhrase.add(patt);
							this.logger.log(tag: \accumulation, msgchunks: nextPhrase, priority: 1);
						},
						\event, {
							//apply operators to event. or rule.
							//note that Pchain applies RTL, and L-systems LTR, so think carefully.
							var squashedPat, listy, nextbit;
							nextPhrase.add(patt);
							this.logger.log(tag: \application, msgchunks: nextPhrase, priority: 1);
							listy = (opStack ++ nextPhrase).asArray;
							listy = [Pset(\depth, depth)] ++ listy;
							([\listy] ++ listy).postln;
							squashedPat = Ptrace(Pchain(*listy));
							[\squashedPat, squashedPat].postln;
							nextbit = [sp.seq(squashedPat)];
							nextStreams = nextStreams ++ nextbit;
							allStreams = allStreams ++ nextbit;
							([\nextStreamsEvent] ++ nextStreams).postln;
							nextPhrase = List.new;
						},
						\rule, {
							// A rule. Expand it and recurse.
							// Do we really want rule application to implicitly group ops?
							this.logger.log(tag: \expansion, msgchunks: patt, priority: 1);
							([\ruled] ++ (this.expressWithContext(sp, opStack ++ nextPhrase, patt, depth: depth+1))).postln;
							nextPhrase = List.new;
						}
					);
				};
			([\nextPhrase] ++nextPhrase).postln;
			([\nextStreams]++ nextStreams.collect({|st| [st, st.identityHash]})).postln;
			([\allStreams]++ allStreams.collect({|st| [st, st.identityHash]})).postln;
		});
		^nextStreams;
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
PSWlist {
	//we use this to indicate that the preceeding transforms should be applied to ALL the contents of this PSParen
	var <weights;
	var <expressions;
	*new {|...weightedList|
		var expressions = Array.new(weightedList.size/2);
		var weights = Array.new(weightedList.size/2);
		weightedList.pairsDo({|weight, expression|
			weights.add(weight);
			expressions.add(expression);
		});
		weights = weights.normalizeSum;
		^super.newCopyArgs(weights, expressions);
	}
	choose {
		^expressions.wchoose(weights) ?? {Array.new};
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
	var <branches;
	*new {|...branches|
		^super.newCopyArgs(branches)
	}
}