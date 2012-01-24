PSSynthPhenotype : PSSynthDefPhenotype {
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
		//override fitness to cause aging in chromosomes
		//var ageNow = this.logicalAge;
		//^(fitness * ageNow / (ageNow.exp));
		^fitness;
	}
}