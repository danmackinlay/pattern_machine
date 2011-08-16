PSEarSwarmPhenotype : PSSynthDefPhenotype {
	fitness {
		var ageNow = this.wallClockAge;
		(ageNow>0).if({
			^fitness/(ageNow);
		}, { ^0 ;});
	}
}