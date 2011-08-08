PSEarSwarmIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a controller abstraction*/
	var <controller;
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
		super.add(phenotype);
		controller.freeIndividual(phenotype);
	}
}
