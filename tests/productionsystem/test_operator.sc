TestPop : PSTestPattern {
	test_op_equality {
		var pop1, pop2, trans1, trans2;
		trans1 = _+1;
		trans2 = _+2;
		pop1 = Pop.new(\a, trans1, \b, trans1);
		pop2 = Pop.new(\a, trans1, \b, trans1);
		this.assert(
			pop1==pop2,
			"Pops that are the same compare so: %==%".format(pop1,pop2)
		);
		pop2 = Pop.new(\a, trans1, \b, trans2);
		this.assert(
			pop1!=pop2,
			"Pops that are the different compare so: %!=%".format(pop1,pop2)
		);
		pop2 = Pop.new(\a, trans1, \c, trans1);
		this.assert(
			pop1!=pop2,
			"Pops that are the different compare so: %!=%".format(pop1,pop2)
		);
		pop2 = Pop.new(\a, trans1, \c, trans2);
		this.assert(
			pop1!=pop2,
			"Pops that are the different compare so: %!=%".format(pop1,pop2)
		);
	}
	test_op_access{
		var pop1, trans1;
		trans1 = Affine1(2,3);
		pop1 = Pop.new(\a,3, \b, trans1);
		this.assertEquals(pop1[\a], 3, "found key a with value 3");
		this.assertEquals(pop1[\b], trans1, "found key b with value Affine1(2,3)");
	}
	test_basic_application {
		var op, ev, patt, steps;
		op=Pop(\delta, Affine1(2,1));
		ev=P1bind(\note,1,\delta,2);
		patt = op <> ev;
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 1, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 5));
	}
	test_basic_composition {
		var op1, op2, ev, patt, steps;
		op1=Pop(\delta, Affine1(2,1), \note, Affine1(1,1));
		op2=Pop(\delta, Affine1(3,1), \dur, Affine1(2,2));
		ev=P1bind(\note,1,\delta,2,\dur, 3);
		patt = op1 <> op2;
		patt = patt <> ev;
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 1, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 2, 'delta': 15, 'dur': 8));
	}
	test_const_composition {
		var op1, op2, op3, op4, ev;
		op1=Pop(\delta, Affine1(8,1));
		op2=Pop(\delta, 7);
		op3=op1<>op2;
		op4=op2<>op1;
		this.assertEquals(op3[\delta], 57, "Composed Affine1 with constant");
		this.assertEquals(op4[\delta], 7, "Composed constant with Affine1");
	}
	test_pcomp {
		var patt1, patt2,steps;
		patt1=Pbind(\delta, 2);
		patt2=Pcomp(Pfindur(5, _))<>patt1;
		steps = this.class.expressPattern(patt2);
		this.assertEquals(steps.size, 3, "correct number of steps");
		this.assertEquals(steps[0][\delta], 2, "Composed pattern with Pfindur");
		this.assertEquals(steps[1][\delta], 2, "Composed pattern with Pfindur");
		this.assertEquals(steps[2][\delta], 1, "Composed pattern with Pfindur");
	}
}
