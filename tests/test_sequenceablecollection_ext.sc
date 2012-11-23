TestSequenceableCollectionExtensions : UnitTest {
	test_application {
		this.assertFloatEquals([1,2,3].reverseReduce('/'), 1.5);
		this.assertFloatEquals([1,2,3].reduce('/'), 1/6);
	}
}