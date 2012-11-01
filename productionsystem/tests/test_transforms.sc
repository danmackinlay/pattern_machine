TestAffine1 : UnitTest {
	test_application {
		[[-1,0,1,10],[-3,0,3],[-5,0,5]].allTuples(12).do({|abc|
			var a, b, c;
			#a, b, c = abc;
			this.assertEquals(Affine1(a, b).value(c), (c*a)+b, "Affine1(%,%).value(%)==(%*%)+%".format(a,b,c,c,a,b));
		})
	}
	/*test_affaff_composition {
		5.do({
			var a, b, c, d, trans1, trans2, ans;
			# a, b, c, d, e = 5.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = Affine1(c, d);
			this.assertEquals(
				trans.value(trans2.value(e)),
				(trans1<>trans2).value(e),
				"%.(%.(%))==(%<>%)(%)".format(trans1,trans2,e,trans1,trans2,e)
			);
		});
	}*/
	test_negation {
		3.do({
			var a, b, trans1, trans2;
			# a, b = 2.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1.neg;
			this.assertEquals(
				trans1.mul,
				trans2.mul.neg,
				"%.mul==%.neg==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add,
				trans2.add.neg,
				"%.add==%.neg==%".format(trans1,trans2,trans1.add)
			);
		})
	}
	test_addition {
		3.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 + c;
			this.assertEquals(
				trans1.mul,
				trans2.mul,
				"%.mul==(%).mul==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add + c,
				trans2.add,
				"%.add+%==(%).add==%".format(trans1,c,trans2,trans1.add+c)
			);
		})
	}
	test_subtraction {
		2.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 - c;
			this.assertEquals(
				trans1.mul,
				trans2.mul,
				"%.mul==(%).mul==%".format(trans1,trans2,trans1.mul)
			);
			this.assertEquals(
				trans1.add - c,
				trans2.add,
				"%.add-%==(%).add==%".format(trans1,c,trans2,trans1.add-c)
			);
		})
	}
	test_multiplication {
		2.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand2});
			trans1 = Affine1(a, b);
			trans2 = trans1 * c;
			this.assertEquals(
				trans1.mul*c,
				trans2.mul,
				"%.mul*%==%.mul==%".format(trans1,c,trans2,trans2.mul)
			);
			this.assertEquals(
				trans1.add * c,
				trans2.add,
				"%.add*%==%.add==%".format(trans1,c,trans2,trans2.add)
			);
		})
	}
	test_division {
		2.do({
			var a, b, c, trans1, trans2;
			# a, b, c = 3.collect({10.rand + 1});
			trans1 = Affine1(a, b);
			trans2 = trans1 / c;
			this.assertFloatEquals(
				trans1.mul/c,
				trans2.mul,
				"%.mul/%==%.mul==%".format(trans1,c,trans2,trans2.mul)
			);
			this.assertFloatEquals(
				trans1.add / c,
				trans2.add,
				"%.add/%==%.add==%".format(trans1,c,trans2,trans2.add)
			);
		})
	}
}