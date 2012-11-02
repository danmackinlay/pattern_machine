TestPSPattern : UnitTest {
	*expressPattern {|patt, defaultEv, limit=100, suppressZeroRests=true|
		var stream, accept, steps=Array.new;
		defaultEv = defaultEv ? Event.default;
		stream = patt.asStream;
		steps = stream.nextN(limit*2, defaultEv.copy);
		steps = steps.select(_.notNil);
		accept = {|ev| true;};
		//"acceptor" function for non-zero-length-rest events, which proliferate with branching
		suppressZeroRests.if({
			accept = {|ev|
				(ev[\isRest] ? false).if(
					{
						(ev[\delta] == 0).if({false}, {true});
					}, {
						true
					};
				);
			};
		});
		steps = steps.select(accept);
		steps = steps[0..limit.min(steps.size)];
		^steps;
	}
	assertAContainsB{|a,b, message=""|
		//makes sure that A contains all the keys that B does, with the same values
		(message.size>0).if({message = message ++ ": "});
		b.pairsDo({|key, bval|
			var aval;
			this.assert(a.includesKey(key), message ++ "key % found".format(key), onFailure: {"key '%' not found in %".format(key, a).postln});
			aval = a[key];
			this.assertEquals(aval, bval, message ++ "key % equal in both (%=%)".format(key, aval, bval));
		});
	}
}
TestPS : TestPSPattern {
	test_op_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, [\halfSpeed, \bar, \bar, \halfSpeed, \halfSpeed, \bar]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 3, "Op/Atom association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Op/Atom association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Op/Atom association");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4), "Op/Atom association");
	}
	test_parens {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, 
			[\halfSpeed, PSParen(\bar, \bar), \halfSpeed, \halfSpeed, PSParen(\bar), \bar]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "Parentheses: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Parentheses");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 2), "Parentheses");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4), "Parentheses");
		this.assertAContainsB(steps[3], ('note': 1, 'delta': 1), "Parentheses");
	}
	test_stars {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\one, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, [PSStarN(4, \one)]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "Kleene stars: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 1), "Kleene stars");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Kleene stars");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 1), "Kleene stars");
		this.assertAContainsB(steps[3], ('note': 1, 'delta': 1), "Kleene stars");
	}
	test_arbitrary_symbols {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\halfSpeed, \bar, \bar]));
		this.assertEquals(steps.size, 2, "Arbitrary symbols in asPattern: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Arbitrary symbols in asPattern");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Arbitrary symbols in asPattern");
	}
	test_branching {
		var steps, ps, firstpair, lastpair;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\one, Pob(\note, 1, \delta, 1)) ;
		ps.putAtom(\two, Pob(\note, 2, \delta, 1)) ;
		ps.putAtom(\three, Pob(\note, 3, \delta, 1)) ;
		ps.putAtom(\four, Pob(\note, 4, \delta, 1)) ;
		ps.putRule(\root, [PSBranch([\one, \three], [\two, \four])]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "Branching: correct number of steps");
		firstpair = (steps[0..1]).collect(_.note);
		lastpair = (steps[2..3]).collect(_.note);
		this.assert(firstpair.includes(1), "Branching: note 1 in first pair");
		this.assert(firstpair.includes(2), "Branching: note 2 in first pair");
		this.assert(lastpair.includes(3), "Branching: note 3 in last pair");
		this.assert(lastpair.includes(4), "Branching: note 4 in last pair");
	}
	test_callable_terminals {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, {Pbind(\delta, Pkey(\delta) * 2)}) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\halfSpeed, \bar, \bar]));
		this.assertEquals(steps.size, 2, "Callable terminals: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Callable terminals");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Callable terminals");
	}
	test_callable_tokens_in_rules {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\note, Pob(\note, 1, \delta, 1));
		ps.putRule(\root, [\note, {\note}, \note]);
		steps = this.class.expressPattern(ps.root);
		this.assertEquals(steps.size, 3, "Callable tokens: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 1), "Callable tokens");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Callable tokens");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 1), "Callable tokens");
	}
	
}