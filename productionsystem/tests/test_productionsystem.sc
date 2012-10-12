TestUnitTestErrorHandling : UnitTest {
	test_unittest {
		"in test_unittest".postln;
		"error in method".throw;
		"threw error in test_unittest".postln;
		this.assertEquals(1,1, "1==1, Yay!");
	}
}