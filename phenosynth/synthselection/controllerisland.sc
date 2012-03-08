
PSControllerIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a (presumably server?) controller
	 * abstraction */
	var <>controller;
 	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];
	//Because I re-use MCLD's listensynths, and they approach zero when signals match:
	classvar <defaultFitnessCooker = #[phenosynth, fitness_cookers, zero_peak];
	
	*defaultParams {
		var defParams = super.defaultParams;
		defParams.individualClass = PSSynthPhenotype;
		//These are kinda CPU-heavy
		defParams.populationSize = 50;
		^defParams;
	}
	*new {|params|
		params.pollPeriod ?? {
			params = params.copy;
		}
		^super.new(params).init;
	}
	init {|newController|
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
	play {|controller|
		//pass the controller a reference to me so it can push notifications
		//A pub-sub solution would scale better to future multi-server parallelism
		["playing with island", this.postln];
		this.controller = controller;
		params.pollPeriod ?? {params.pollPeriod = controller.fitnessPollInterval ? 1;};
		controller.connect(this);
		super.play;
	}
	free {
		super.free;
		controller.free;
	}
}
