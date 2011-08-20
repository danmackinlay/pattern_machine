PSEarSwarmPhenotype : PSSynthDefPhenotype {
	var <>lifeSpan = 20;
	fitness {
		var ageNow = this.logicalAge;
		//override fitness to give mean fitness *rate*
		^(fitness * ageNow / (ageNow.exp));
	}
}