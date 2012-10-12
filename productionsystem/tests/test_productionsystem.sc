TestUnitTestErrorHandling : UnitTest {
	test_unittest {
		var troublesomeRoutine = Routine({"error in routine".throw});
		"in test_unittest".postln;
		"error in method".throw;
		"threw error in test_unittest".postln;
		troublesomeRoutine.next;
		this.assertEquals(1,1, "1==1, Yay!");
	}
}