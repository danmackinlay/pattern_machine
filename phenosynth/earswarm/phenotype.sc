PSEarSwarmPhenotype : PSSynthDefPhenotype {
	var <>lifeSpan = 20;
	classvar <synthdef = \ps_reson_saw_2pan;
	
	*setUpMappingToSynthDef {	
		map = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec,
			\pan: \pan.asSpec
		);
	}
	fitness {
		var ageNow = this.logicalAge;
		//override fitness to cause aging in chromosomes
		//^(fitness * ageNow / (ageNow.exp));
		^fitness;
	}
}