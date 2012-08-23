TestPSProductionCoding : UnitTest {
	test_AtomList {
		var coding;
		coding = PSProductionCoding.new;
		coding.put(\a, PSEventOperator.new);
		coding.put(\b, Event.new);
		coding.put(\c, PSEventOperator.new);
		coding.put(\d, Event.new);
		this.assertEquals(
			coding.operators,
			IdentitySet.newFrom([\a,\c]);
		);
		this.assertEquals(
			coding.atoms,
			IdentitySet.newFrom([\b,\d]);
		);
	}
}
