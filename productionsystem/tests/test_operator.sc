TestPOp : TestPSPattern {
	test_op_equality {
		var pop1, pop2, trans1, trans2;
		trans1 = _+1;
		trans2 = _+2;
		pop1 = POp.new(\a, trans1, \b, trans1);
		pop2 = POp.new(\a, trans1, \b, trans1);
		this.assert(
			pop1==pop2,
			"POps that are the same compare so: %==%".format(pop1,pop2)
		);
		pop2 = POp.new(\a, trans1, \b, trans2);
		this.assert(
			pop1!=pop2,
			"POps that are the different compare so: %!=%".format(pop1,pop2)
		);
		pop2 = POp.new(\a, trans1, \c, trans1);
		this.assert(
			pop1!=pop2,
			"POps that are the different compare so: %!=%".format(pop1,pop2)
		);
		pop2 = POp.new(\a, trans1, \c, trans2);
		this.assert(
			pop1!=pop2,
			"POps that are the different compare so: %!=%".format(pop1,pop2)
		);
	}
	test_basic_application {
		var op, ev, patt, steps;
		op=POp(\delta, Affine1(2,1));
		ev=Pob(\note,1,\delta,2);
		patt = op <> ev;
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 1, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 5));
	}
	test_basic_composition {
		var op1, op2, ev, patt, steps;
		op1=POp(\delta, Affine1(2,1), \note, Affine1(1,1));
		op2=POp(\delta, Affine1(3,1), \dur, Affine1(2,2));
		ev=Pob(\note,1,\delta,2,\dur, 3);
		patt = op1 <> op2;
		patt = patt <> ev;
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 1, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 2, 'delta': 15, 'dur': 8));
	}
}
