PSOptimisingSwarm {
	/* handle a swarm of agents optimising.
	This is a little like PSControllerIsland, but not enough that it is worth it
	to subclass.
	There should be some duck-typing possible, though.
	
	Also note that unlike the class hierarchy of the GA-type selection, I 
	make no allowance for non-synth-based selection.
	This is because of Deadlines.
	*/
	
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, zero_peak];
	classvar <defaultInitialChromosomeFactory = #[phenosynth, chromosome_fact, basic];
	classvar <defaultIndividualFactory = #[phenosynth, individual_fact, basic];
	classvar <defaultScoreEvaluator = #[phenosynth, score_evals, chromosomemean];
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, raw];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, basic];

	var <>controller;
	var <>particles;
	var <worker;
	
	var <>params;
	var <>log;

	//These are the main state variables
	var <population;
	var <rawScoreMap;
	var <cookedFitnessMap;
	var <iterations = 0;
	var <velocityTable;
	var <bestKnownTable;
	var <neighbourTable;
	
	//flag to stop iterator gracefuly.
	var playing = false;

	/*
	Here are the variables that hold the operator functions.
	Paths are coerced to functions at instantiation time to avoid problems with
	not knowing when the Library gets filled.
	*/
	var <initialChromosomeFactory;
	var <individualFactory;
	var <scoreEvaluator;
	var <scoreCooker;
	var <terminationCondition;

	// default values for that parameter thing
	*defaultParams {
		^(
			\initialChromosomeSize: 4,
			\individualFactory: PSPhenotype,
			\stopIterations: 1000,
			\individualFactory: PSSynthPhenotype,
			\populationSize: 40,
			\log: NullLogger.new
		);
	}
	*new {|params, log|
		var thisNew = super.newCopyArgs(
			this.defaultParams.updatedFrom(params ? Event.new)
		).init;
		^thisNew;
	}
	initialChromosomeFactory_ {|fn|
		initialChromosomeFactory = LoadLibraryFunction(fn);
	}
	individualFactory_ {|fn|
		individualFactory = LoadLibraryFunction(fn);
	}
	scoreEvaluator_ {|fn|
		scoreEvaluator = LoadLibraryFunction(fn);
	}
	scoreCooker_ {|fn|
		scoreCooker = LoadLibraryFunction(fn);
	}
	terminationCondition_ {|fn|
		terminationCondition = LoadLibraryFunction(fn);
	}
	init {
		population = IdentitySet.new(100);
		rawScoreMap = IdentityDictionary.new(100);
		cookedFitnessMap = IdentityDictionary.new(100);
		velocityTable = IdentityDictionary.new(100);
		neighbourTable = IdentityDictionary.new(100);
		bestKnownTable = IdentityDictionary.new(100);
		this.initOperators;
	}
	initOperators {
		this.initialChromosomeFactory = this.class.defaultInitialChromosomeFactory;
		this.individualFactory = this.class.defaultIndividualFactory;
		this.scoreEvaluator = this.class.defaultScoreEvaluator;
		this.scoreCooker = this.class.defaultScoreCooker;
		this.terminationCondition = this.class.defaultTerminationCondition;
	}
	add {|phenotype|
		var res, velocity, neighbours;
		res = controller.playIndividual(phenotype);
		res.isNil.if({
			//no busses available to play on
			params.log.log(msgchunks: ["Could not add phenotype", phenotype], tag: \resource_exhausted);
		}, {
			population.add(phenotype);
			velocityTable[phenotype] = [0,0,0,0];
			neighbourTable[phenotype] = Set[];
			bestKnownTable[phenotype] = 0;
		});
	}
	remove {|phenotype|
		population.remove(phenotype);
		rawScoreMap.removeAt(phenotype);
		cookedFitnessMap.removeAt(phenotype);
		velocityTable.removeAt(phenotype);
		neighbourTable.removeAt(phenotype);
		bestKnownTable.removeAt(phenotype);
		controller.freeIndividual(phenotype);
	}
	populate {
		params.populationSize.do({
			this.add(initialChromosomeFactory.value(params));
		});
		this.createNeighbourhood;
	}
	evaluate {
		population.do({|phenotype|
			this.setFitness(phenotype, scoreEvaluator.value(params, phenotype));
			phenotype.incAge;
		});
		cookedFitnessMap = scoreCooker.value(params, rawScoreMap);
	}
	setFitness {|phenotype, value|
		rawScoreMap[phenotype] = value;
	}
	
	play {|controller|
		var clock;
		//pass the controller a reference to me so it can push notifications
		this.controller = controller;
		params.pollPeriod ?? {params.pollPeriod = controller.fitnessPollInterval ? 1;};
		controller.connect(this);
		this.populate;
		clock = TempoClock.new(params.pollPeriod.reciprocal, 1);
		playing = true;
		worker = Routine.new({
			while(
				{(terminationCondition.value(
					params, population, iterations
					).not) &&
					playing
				}, {
					this.tend;
					1.yield;
				}
			);
		}).play(clock);
	}
	free {
		super.free;
		controller.free;
	}
}
	