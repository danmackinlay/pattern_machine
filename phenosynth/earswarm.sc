PSEarSwarmIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a controller abstraction*/
	var <controller;
	*defaultParams {
		var defParams = super.defaultParams;
		defParams.individualClass = PSSynthDefPhenotype;
		^defParams;
	}
	*new {| params, pollPeriod=1, controller|
		^super.new(params).init(pollPeriod, controller);
	}
	init {|newPollPeriod, newController|
		controller = newController;
		^super.init(newPollPeriod);
	}
	add {|phenotype|
		super.add(phenotype);
		controller.playIndividual(phenotype);
	}
	remove {|phenotype|
		super.remove(phenotype);
		controller.freeIndividual(phenotype);
	}
	free {
		^super.free;
		//TODO:
		//controller.free;
	}
}
