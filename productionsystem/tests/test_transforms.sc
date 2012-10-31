TestAffine1 : UnitTest {
	test_application {
		[[-1,0,1,10],[-3,0,3],[-5,0,5]].allTuples(12).do({|abc|
			var a, b, c;
			#a, b, c = abc;
			this.assertEquals(Affine1(a, b).value(c), (c*a)+b, "Affine1(%,%).value(%)==(%*%)+%".format(a,b,c,c,a,b));
		})
	}
}