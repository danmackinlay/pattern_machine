PSControllerIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a (presumably server?) controller
	 * abstraction */
	var <>controller;
	//Because I oft-times re-use MCLD's listensynths, and they approach zero when signals match:
 	classvar <defaultScoreCooker = #[phenosynth, score_cookers, zero_peak];

	*defaultParams {
		var defParams = super.defaultParams;
		defParams.individualFactory = PSSynthPhenotype;
		//These are kinda CPU-heavy
		defParams.populationSize = 40;
		^defParams;
	}
	init {
		^super.init;
	}
	add {|phenotype|
		var res;
		res = controller.playIndividual(phenotype);
		res.notNil.if({
			super.add(phenotype);
		}, {
			params.log.log(msgchunks: ["Could not add phenotype", phenotype], tag: \resource_exhausted);
		});
	}
	remove {|phenotype|
		super.remove(phenotype);
		controller.freeIndividual(phenotype);
	}
	play {|controller|
		//pass the controller a reference to me so it can push notifications
		//A pub-sub solution would scale better to future multi-server parallelism
		this.controller = controller;
		params.pollPeriod ?? {params.pollPeriod = controller.fitnessPollInterval ? 1;};
		controller.connect(this);
		super.play;
	}
	free {
		super.free;
		controller.free;
	}
	rankedPopulation {
		//return all population that have a fitness, ranked in descending order thereof.
		//Individuals that do not yet have a fitness are not returned
		^population.selectAs(
			{|i| cookedFitnessMap[i].notNil}, Array
		).sort({|a, b| cookedFitnessMap[a] > cookedFitnessMap[b] });
	}
	
}
