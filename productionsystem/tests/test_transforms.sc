TestAffine1 : UnitTest {
	var randomReps = 2;
	test_application {
		[[-1,0,1,10],[-3,0,3],[-5,0,5]].allTuples(12).do({|abc|
			var a, b, c;
			#a, b, c = abc;
			this.assertEquals(Affine1(a, b).value(c), (c*a)+b, "Affine1(%,%).value(%)==(%*%)+%".format(a,b,c,c,a,b));
		})
	}
	test_nilsafe {
		this.assertEquals(Affine1(1, 2).value(nil), nil, "Affine1(1,2).value(nil)==nil (no Exception thrown)");
		{
			var tmp=Affine1(1, 2,nilSafe:false).value(nil);
			this.assert(false, "Affine1 is nilSafe when it shouldn't be");
		}.try({|err|
			this.assert(true, "Affine1 is not nilSafe when it shouldn't be, as desired");
		});
	}
	test_affaff_equality {
			var a, b, trans1, trans2, trans3, trans4;
			# a, b = 2.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = Affine1(a, b);
			trans3 = Affine1(a+1, b);
			trans4 = Affine1(a+1, b+1);
			this.assertEquals(
				trans1,
				trans2,
				"Two Affines are equal if their params are: %==%".format(trans1,trans2)
			);
			this.assert(
				trans1 != trans3,
				"Two Affines are unequal if their params are: %==%".format(trans1,trans3)
			);
			this.assert(
				trans1 != trans4,
				"Two Affines are unequal if their params are: %==%".format(trans1,trans4)
			);
	}
	test_affaff_composition {
		randomReps.do({
			var a, b, c, d, x, ycomp, yapp, trans1, trans2, transcomp, transapp;
			# a, b, c, d, x = 5.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = Affine1(c, d);
			transcomp = trans1 <> trans2;
			transapp = {|in| trans1.(trans2.(in))};
			ycomp = transcomp.(x);
			yapp = transapp.(x);
			this.assertEquals(
				yapp,
				ycomp,
				"Affine transforms composed are the same as applied: %<>%.(%)==%.(%)==%".format(trans1,trans2,x,transcomp,x,yapp)
			);
			this.assertEquals(
				transcomp.class,
				trans1.class,
				"Affine transforms closed under composition: %.class(==%)==%.class(==%)".format(transcomp,transcomp.class,trans1,trans1.class)
			);
		})
	}
	test_affother_composition {
		randomReps.do({
			var a, b, c, d, x, trans1, trans2, ycomp, yapp, transcomp, transapp, ycomprev, yapprev, transcomprev, transapprev;
			# a, b, c, d, x = 5.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = (c*_ + d);
			transcomp = trans2 <> trans1;
			transapp = {|in| trans2.(trans1.(in))};
			ycomp = transcomp.(x);
			yapp = transapp.(x);
			this.assertEquals(
				yapp,
				ycomp,
				"Affine transforms produce correct result when composed with others: %.(%.(%))==%<>%.(%)==%".format(trans1,trans2,x,trans1,trans2,x, yapp)
			);
			transcomprev = trans1 <> trans2;
			transapprev = {|in| trans1.(trans2.(in))};
			ycomprev = transcomprev.(x);
			yapprev = transapprev.(x);
			this.assertEquals(
				yapprev,
				ycomprev,
				"Affine transforms produce correct result when composed with others, backwards: %.(%.(%))==%<>%.(%)==%".format(trans1,trans2,x,trans1,trans2,x, yapprev)
			);
		})
	}
	test_negation {
		randomReps.do({
			var a, b, trans1, trans2;
			# a, b = 2.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1.neg;
			this.assertEquals(
				trans1.mul,
				trans2.mul.neg,
				"Affine transforms closed under negation: %.mul==%.neg==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add,
				trans2.add.neg,
				"Affine transforms closed under negation: %.add==%.neg==%".format(trans1,trans2,trans1.add)
			);
		})
	}
	test_addition {
		randomReps.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 + c;
			this.assertEquals(
				trans1.mul,
				trans2.mul,
				"Affine transforms closed under scalar addition: %.mul==(%).mul==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add + c,
				trans2.add,
				"Affine transforms closed under scalar addition: %.add+%==(%).add==%".format(trans1,c,trans2,trans1.add+c)
			);
		})
	}
	test_subtraction {
		randomReps.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 - c;
			this.assertEquals(
				trans1.mul,
				trans2.mul,
				"Affine transforms closed under scalar subtraction: %.mul==(%).mul==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add - c,
				trans2.add,
				"Affine transforms closed under scalar subtraction: %.add-%==(%).add==%".format(trans1,c,trans2,trans1.add-c)
			);
		})
	}
	test_multiplication {
		randomReps.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 * c;
			this.assertEquals(
				trans1.mul*c,
				trans2.mul,
				"Affine transforms closed under scalar multiplication: %.mul*%==%.mul==%".format(trans1,c,trans2,trans2.mul)
			);
			this.assertEquals(
				trans1.add * c,
				trans2.add,
				"Affine transforms closed under scalar multiplication: %.add*%==%.add==%".format(trans1,c,trans2,trans2.add)
			);
		})
	}
	test_division {
		randomReps.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand + 1});
			trans1 = Affine1(a, b);
			trans2 = trans1 / c;
			this.assertFloatEquals(
				trans1.mul/c,
				trans2.mul,
				"Affine transforms closed under scalar division: %.mul/%==%.mul==%".format(trans1,c,trans2,trans2.mul)
			);
			this.assertFloatEquals(
				trans1.add / c,
				trans2.add,
				"Affine transforms closed under scalar division: %.add/%==%.add==%".format(trans1,c,trans2,trans2.add)
			);
		})
	}
}