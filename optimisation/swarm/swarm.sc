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
	classvar <defaultIndividualFactory = #[phenosynth, individual_fact, defer_to_constructor];
	classvar <defaultScoreEvaluator = #[phenosynth, score_evals, chromosomemean];
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, raw];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, never];

	var <>params;

	var <>controller;
	var <>particles;
	var <worker;

	//These are the main state variables
	var <population;
	var <rawScoreMap;
	var <cookedFitnessMap;
	var <iterations = 0;
	var <velocityTable;
	var <bestKnownPosTable;
	var <bestKnownFitnessTable;
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
			\stepSize: 0.01,
			\clockRate: 10.0,
			\selfTracking: 0.05,
			\groupTracking: 0.1,
			\momentum: 0.9,
			\linksTransitive: false,
			\individualConstructor: PSSynthPhenotype,
			\populationSize: 40,
			\log: NullLogger.new
		);
	}
	*new {|params|
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
		bestKnownPosTable = IdentityDictionary.new(100);
		bestKnownFitnessTable = IdentityDictionary.new(100);
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
			velocityTable[phenotype] = {1.rand2}.dup(params.initialChromosomeSize);
			neighbourTable[phenotype] = Set[];
			bestKnownPosTable[phenotype] = 0;
			bestKnownFitnessTable[phenotype] = phenotype.chromosome;
		});
	}
	remove {|phenotype|
		population.remove(phenotype);
		rawScoreMap.removeAt(phenotype);
		cookedFitnessMap.removeAt(phenotype);
		velocityTable.removeAt(phenotype);
		neighbourTable.removeAt(phenotype);
		bestKnownPosTable.removeAt(phenotype);
		bestKnownFitnessTable.removeAt(phenotype);
		controller.freeIndividual(phenotype);
	}
	populate {
		params.populationSize.do({
			var noob, chromosome;
			chromosome = initialChromosomeFactory.value(params);
			noob = individualFactory.value(params, chromosome);
			this.add(noob);
		});
		// this.createTopology;
	}
	// createTopology {|linksPerNode=3|
	// 	//create a Renyi whole random social graph all at once
	// 	// this is easier than bit-by-bit if we want to avoid preferential attachment dynamics
	// 	var nLinks = params.populationSize * linksPerNode;
	// 	nLinks.do({
	// 		this.addLink(population.choose, population.choose);
	// 	});
	// }
	addLink{|src,dest|
		neighbourTable[src] = dest;
		params.linksTransitive.if({
			neighbourTable[dest] = src;
		});
	}
	setFitness {|phenotype, value|
		rawScoreMap[phenotype] = value;
	}
	
	play {|controller|
		var clock;
		//pass the controller a reference to me so it can push notifications
		this.controller = controller;
		params.clockRate ?? {params.clockRate = controller.fitnessPollRate ? 1;};
		controller.connect(this);
		this.populate;
		clock = TempoClock.new(params.clockRate, 1);
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
	tend {
		/*Note there is a problem here at the moment with asynchronous updating
		particles modify the bestness tables in situ
		
		Also fitness is noisy because of a) lags and b) asynchronous fitness polling.
		*/

		cookedFitnessMap = scoreCooker.value(params, rawScoreMap);
		
		population.do({|phenotype|
			var myCurrentFitness, myBestFitness, myNeighbourhoodBestFitness;
			var myCurrentPos, myBestPos, myNeighbourhoodBestPos;
			var myVel, myNeighbourhood;

			myNeighbourhood = neighbourTable[phenotype];

			myCurrentPos = phenotype.chromosome;
			myCurrentFitness = cookedFitnessMap[phenotype];
			myBestPos = bestKnownPosTable[phenotype];
			myBestFitness = bestKnownFitnessTable[phenotype];
			params.log.log(msgchunks: [
					\pos, myCurrentPos,
					\fit, myCurrentFitness,
					\bestpos, myBestPos,
					\bestfit, myBestFitness
				], tag: \selecting);
			(myCurrentFitness>myBestFitness).if({
				myBestFitness = myCurrentFitness;
				myBestPos = myCurrentPos;
			});

			myVel = velocityTable[phenotype];
			myVel = (params.momentum * myVel) +
				params.thisTracking * (myCurrentPos - myBestPos);
			myCurrentPos = myCurrentPos + myVel * (params.stepSize);
			
			phenotype.chromosome = myCurrentPos;
			controller.updateIndividual(phenotype);
			
			bestKnownPosTable[phenotype] = myBestPos;
			bestKnownFitnessTable[phenotype] = myBestFitness;
		});
		params.log.log(msgchunks: [\tending], tag: \nuffin);
		iterations = iterations + 1;
	}
	
	free {
		super.free;
		controller.free;
	}
}
	