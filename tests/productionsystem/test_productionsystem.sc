TestProductionSystem : PSTestPattern {
	test_long_rules {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, P1bind(\note, 1, \delta, 1)) ;
		ps.putRule(\root, \halfSpeed, \bar, \bar, \halfSpeed, \halfSpeed, \bar);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 3, "Op/Atom association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Op/Atom association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Op/Atom association");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4), "Op/Atom association");
	}
	test_op_atom_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, P1bind(\note, 1, \delta, 1)) ;
		ps.putRule(\root, \halfSpeed, \bar, \bar, \halfSpeed, \halfSpeed, \bar);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 3, "Op/Atom association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Op/Atom association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Op/Atom association");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4), "Op/Atom association");
	}
	test_rule_op_rule_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		//Do operators bind across the boundaries of rules?
		// (Extra credit: SHOULD they?)
		//This buys us the ability to have rules at are only operators,
		// but at the expense of having trailing operators applied in weird contexts 
		ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2))) ;
		ps.putAtom(\note, P1bind(\note, 1, \dur, 1)) ;
		ps.putRule(\op, \halfSpeed);
		ps.putRule(\atom, \note);
		ps.putRule(\root, \op, \atom, \op, \op, \atom);
		steps = this.class.expressPattern(ps.root);
		this.assertEquals(steps.size, 2, "RuleOp/Rule association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "RuleOp/Rule association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 4), "RuleOp/Rule association");
	}
	test_rule_rule_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
		ps.putAtom(\note, P1bind(\note, 1, \dur, 1));
		ps.putRule(\part1, \halfSpeed, \note, \halfSpeed);
		ps.putRule(\part2, \note, \halfSpeed, \note);
		ps.putRule(\root, \part1, \part2);
		steps = this.class.expressPattern(ps.root);
		this.assertEquals(steps.size, 3, "Rule/Rule association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Rule/Rule association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 2), "Rule/Rule association");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 2), "Rule/Rule association");
	}
	test_rule_op_atom_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2))) ;
		ps.putAtom(\note, P1bind(\note, 1, \dur, 1)) ;
		ps.putRule(\op, \halfSpeed);
		ps.putRule(\root, \op, \note, \op, \op, \note);
		steps = this.class.expressPattern(ps.root);
		this.assertEquals(steps.size, 2, "RuleOp/Atom association: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "RuleOp/Atom association");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 4), "RuleOp/Atom association");
	}
	test_parens {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, P1bind(\note, 1, \delta, 1)) ;
		ps.putRule(\root, 
			\halfSpeed, PSParen(\bar, \bar), \halfSpeed, \halfSpeed, PSParen(\bar), \bar);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "Parentheses: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Parentheses");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 2), "Parentheses");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4), "Parentheses");
		this.assertAContainsB(steps[3], ('note': 1, 'delta': 1), "Parentheses");
	}
	test_stars_extend {
		var steps, ps = PSProductionSystem.new;
		ps.putAtom(\one, P1bind(\note, 1, \delta, 1)) ;
		ps.putRule(\root, PSStarN(4, \one));
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "Kleene starred atoms: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 1), "Kleene starred atoms");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Kleene starred atoms");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 1), "Kleene starred atoms");
		this.assertAContainsB(steps[3], ('note': 1, 'delta': 1), "Kleene starred atoms");
	}
	test_star_association {
		var steps, ps = PSProductionSystem.new;
		ps.putOp(\starop, Pop(\note, Affine1(1,1)));
		ps.putAtom(\note, P1bind(\note, 1, \delta, 1));
		ps.putRule(\root, PSStarN(2, \starop), \note, \note);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 2, "Kleene starred ops: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 3, 'delta': 1), "Kleene starred ops");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Kleene starred ops");
	}
	test_arbitrary_symbols {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, P1bind(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\halfSpeed, \bar, \bar]));
		this.assertEquals(steps.size, 2, "Arbitrary symbols in asPattern: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Arbitrary symbols in asPattern");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Arbitrary symbols in asPattern");
	}
	test_token_choice_chooses {
		var ps, deltasfound;
		//This test isn't deterministic (wel, it is up to 1 in 2^20). How could it be made so?
		ps = PSProductionSystem.new;
		deltasfound = Set.new;
		ps.putRule(\changeSpeed, PSChoice(1, [\half, \note], 1, [\third, \note]));
		ps.putOp(\half, Pop(\stretch, Affine1(2)));
		ps.putOp(\third, Pop(\stretch, Affine1(3)));
		ps.putAtom(\note, P1bind(\note, 1, \delta, 1)) ;
		20.do({
			this.class.expressPattern(ps.asPattern([\changeSpeed])).do({|step|
				deltasfound.add(step[\stretch])
			});
		});
		this.assertEquals(deltasfound, Set[2,3], "PSChoice selects at random.");
	}
	test_token_choice_in_current_context {
		var ps, steps;
		ps = PSProductionSystem.new;
		ps.putRule(\changeSpeed, PSChoice(1, [\half], 1, [\half]));
		ps.putOp(\half, Pop(\stretch, Affine1(2)));
		ps.putAtom(\note, P1bind(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\changeSpeed, \note]));
		this.assertEquals(steps.size, 1, "PSChoice expands in current context: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'stretch': 2), "PSChoice expands in current context");
	}
	test_branching {
		var steps, ps, firstpair, lastpair;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\one, P1bind(\note, 1, \delta, 1)) ;
		ps.putAtom(\two, P1bind(\note, 2, \delta, 1)) ;
		ps.putAtom(\three, P1bind(\note, 3, \delta, 1)) ;
		ps.putAtom(\four, P1bind(\note, 4, \delta, 1)) ;
		ps.putRule(\root, PSBranch([\one, \three], [\two, \four]));
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
		ps.putAtom(\bar, P1bind(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\halfSpeed, \bar, \bar]));
		this.assertEquals(steps.size, 2, "Callable terminals: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2), "Callable terminals");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Callable terminals");
	}
	test_callable_tokens_in_rules {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\note, P1bind(\note, 1, \delta, 1));
		ps.putRule(\root, \note, {\note}, \note);
		steps = this.class.expressPattern(ps.root);
		this.assertEquals(steps.size, 3, "Callable tokens: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 1), "Callable tokens");
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1), "Callable tokens");
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 1), "Callable tokens");
	}
	
}