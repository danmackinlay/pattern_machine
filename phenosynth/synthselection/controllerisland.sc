
PSControllerIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a (presumably server?) controller
	 * abstraction */
	var <controller;
 	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];
	//Because I re-use MCLD's listensynths, and they approach zero wheen signals match:
	classvar <defaultFitnessCooker = #[phenosynth, fitness_cookers, zero_peak];
	
	*defaultParams {
		var defParams = super.defaultParams;
		defParams.individualClass = PSSynthPhenotype;
		//These are kinda CPU-heavy
		defParams.populationSize = 50;
		^defParams;
	}
	*new {|params, controller|
		^super.new(params).init(controller);
	}
	init {|newController|
		controller = newController;
		^super.init;
	}
	add {|phenotype|
		super.add(phenotype);
		controller.playIndividual(phenotype);
	}
	remove {|phenotype|
		super.remove(phenotype);
		controller.freeIndividual(phenotype);
	}
	play {
		//pass the controller a refernce to me so it can tell me things 
		//asynchronously
		["playing with island", this.postln];
		controller.play(this);
		super.play;
	}
	free {
		super.free;
		controller.free;
	}
}
