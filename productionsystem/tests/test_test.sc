TestUnitTestErrorHandling : UnitTest {
	test_unittest {
		"in test_unittest".postln;
		this.assertEquals(1, 1, "1==1, Yay!");
		this.assertEquals(1, 2, "1==2, Yay!");
	}
	test_unittest_with_exception_handler {
		"in test_unittest_with_exception_handler".postln;
		Error("error in method").throw;
		//these guys do not get executed, as expected.
		this.assertEquals(3,3, "3==3, Yay!");
		this.assertEquals(3,4, "3==4, Yay!");
	}
	test_unittest_after_exception {
		//This runs fine.
		"in test_unittest_after_exception".postln;
		this.assertEquals(5,5, "5==5, even after an exception! Yay!");
	}
}
