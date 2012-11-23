TestSimpleNumberExtension : UnitTest {
	test_application {
		this.assertFloatEquals(5.roundDown(2), 4);
		this.assertFloatEquals(5.5.roundDown(2), 4);
		this.assertFloatEquals(5.5.roundDown(1), 5);
		this.assertFloatEquals(5.55.roundDown(0.2), 5.4);
		this.assertFloatEquals(5.5.roundDown(0.5), 5.5);
	}
}