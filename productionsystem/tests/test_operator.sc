TestPSEventOperator : TestPSPattern {
	test_OperatorCreationShortcuts {
		var createdNewFilled, createdNewFrom, createdNewEmpty;
		createdNewFrom = PSEventOperator.newFrom((a:1, b:2));
		createdNewFilled = PSEventOperator(\a,1,\b,2);
		createdNewEmpty = PSEventOperator.new;
		createdNewEmpty[\a] = 1;
		createdNewEmpty[\b] = 2;
		this.assertEquals(
			createdNewFrom,
			createdNewFilled,
		);
		this.assertEquals(
			createdNewFrom,
			createdNewEmpty,
		);
		this.assertEquals(
			createdNewEmpty,
			createdNewFilled,
		);
	}
	test_OperatorOperatorApply {
		var left,right,target,combined,testnums;
		left = PSEventOperator.newFrom((
			a: _*3,
			b: _*2
		));
		right = PSEventOperator.newFrom((
			b: _+1,
			c: _*2
		));
		combined = left.applyTo(right);
		target = PSEventOperator.newFrom((
			a: _*3,
			b: {|i| (i+1)*2},
			c: _*2
		));
		testnums=[-1, 0, 0.1, 9.5];
		testnums.do({|n|
			[\a,\b,\c].do({|key|
				this.assertFloatEquals(
					combined.at(key).value(n),
					target.at(key).value(n),
					//"failure of Operator-Operator composition at key:\n\t" + key + "\nwith test input:\n\t"+n
				);
			});
		});
	}
	test_OperatorEventApply {
		var left,right,target,combined;
		left = PSEventOperator.newFrom((
			a: _*3,
			b: _+2
		));
		right = (
			b: 2.5,
			c: 3.25
		);
		combined = left.applyTo(right);
		target = PSEventOperator.newFrom((
			b: 4.5,
			c: 3.25
		));
		[\a,\b,\c].do({|key|
			this.assertEquals(
				combined.at(key),
				target.at(key),
				//"failure of Operator-Event composition at key:\n\t" + key + "\nwith test input:\n\t"+n
			);
		});
	}
}

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
	/*test_OperatorOperatorApply {
		var left,right,target,combined,testnums;
		left = POp.newFrom((
			a: _*3,
			b: _*2
		));
		right = POp.newFrom((
			b: _+1,
			c: _*2
		));
		combined = left.applyTo(right);
		target = POp.newFrom((
			a: _*3,
			b: {|i| (i+1)*2},
			c: _*2
		));
		testnums=[-1, 0, 0.1, 9.5];
		testnums.do({|n|
			[\a,\b,\c].do({|key|
				this.assertFloatEquals(
					combined.at(key).value(n),
					target.at(key).value(n),
					//"failure of Operator-Operator composition at key:\n\t" + key + "\nwith test input:\n\t"+n
				);
			});
		});
	}
	test_OperatorEventApply {
		var left,right,target,combined;
		left = POp.newFrom((
			a: _*3,
			b: _+2
		));
		right = (
			b: 2.5,
			c: 3.25
		);
		combined = left.applyTo(right);
		target = POp.newFrom((
			b: 4.5,
			c: 3.25
		));
		[\a,\b,\c].do({|key|
			this.assertEquals(
				combined.at(key),
				target.at(key),
				//"failure of Operator-Event composition at key:\n\t" + key + "\nwith test input:\n\t"+n
			);
		});
		}*/
}
