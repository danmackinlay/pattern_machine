PSEarSwarmPhenotype : PSSynthDefPhenotype {
	fitness {
		//override fitness to give mean fitness *rate*
		var ageNow = this.wallClockAge;
		(ageNow>0).if({
			^fitness/(ageNow);
		}, { ^0 ;});
	}
}