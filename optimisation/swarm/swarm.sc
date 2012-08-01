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
			\stepSize: 0.1,
			\clockRate: 10.0,
			\selfTracking: 2.0,
			\groupTracking: 2.0,
			\momentum: 1.05,
			\maxVel: 1.0,
			//\linksTransitive: false,
			\neighboursPerNode:3,
			\individualConstructor: PSSynthDefPhenotype,
			\populationSize: 40,
			\log: NullLogger.new,
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
			velocityTable[phenotype] = {1.0.rand2}.dup(params.initialChromosomeSize);
			neighbourTable[phenotype] = Array.newFrom([phenotype]);
			bestKnownPosTable[phenotype] = nil;
			bestKnownFitnessTable[phenotype] = nil;
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
		this.createTopology;
	}
	createTopology {
		//create a whole Renyi random social graph all at once
		// this is easier than bit-by-bit if we want to avoid preferential attachment dynamics
		// Maybe preferential attachment dynamics is desirable though? I dunno.
		var nLinks = [params.neighboursPerNode, params.populationSize-1].maxItem;
		// Not supported at the moment because of pains of avoiding duplicates
		//(params.linksTransitive).if({nLinks = nLinks / 2;});
		population.do({|here|
			var unusedNeighbours = IdentitySet.newFrom(population); //this copies, right?
			unusedNeighbours.remove(here);
			nLinks.do({
				var there;
				there = unusedNeighbours.choose;
				unusedNeighbours.remove(there);
				this.addLink(here, there);
			});
		});
	}
	addLink{|src, dest|
		neighbourTable[src] = neighbourTable[src].add(dest);
		/*params.linksTransitive.if({
			neighbourTable[dest] = neighbourTable[dest].add(src);
		});*/
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
		/*Note there is a potential problem with asynchronous updating:
		particles modify the bestness tables in situ
		
		Also fitness is noisy because of a) lags and b) asynchronous fitness polling.
		*/

		cookedFitnessMap = scoreCooker.value(params, rawScoreMap);
				
		cookedFitnessMap.keys.do({|phenotype|
			var myCurrentFitness, myBestFitness, myNeighbourhoodBestFitness;
			var myCurrentPos, myBestPos, myNeighbourhoodBestPos, myNextPos;
			var myBestNeighbour;
			var myVel, myNeighbourhood;
			var myDelta, myNeighbourhoodDelta;
			var vecLen;

			myNeighbourhood = neighbourTable[phenotype];

			myCurrentPos = phenotype.chromosome;
			vecLen = phenotype.chromosome.size;
			
			myCurrentFitness = cookedFitnessMap[phenotype];
			myBestPos = bestKnownPosTable[phenotype] ? myCurrentPos;
			myBestFitness = bestKnownFitnessTable[phenotype] ? myCurrentFitness;
			myDelta = (myBestPos - myCurrentPos);
			
			myBestNeighbour = myNeighbourhood[
				myNeighbourhood.maxIndex({|neighbour|
					cookedFitnessMap[neighbour]
				});
			];
			myNeighbourhoodBestPos = myBestNeighbour.chromosome;
			myNeighbourhoodBestFitness = cookedFitnessMap[myBestNeighbour];
			myNeighbourhoodDelta = (myNeighbourhoodBestPos - myCurrentPos);
			
			myVel = velocityTable[phenotype];
			
			params.log.log(msgchunks: [\premove,
					\vel, myVel,
					\pos, myCurrentPos,
					\mydelta, myDelta,
				], priority: -1,
				tag: \moving);
			
			myVel = (params.momentum * myVel) +
				(params.selfTracking * ({1.0.rand}.dup(vecLen)) * myDelta) +
				(params.groupTracking * ({1.0.rand}.dup(vecLen)) * myDelta);
			myVel = myVel.clip2(params.maxVel);
			myNextPos = (myCurrentPos + (myVel * (params.stepSize))).clip(0.0, 1.0);
			//allow clipping of velocities to reflect hitting the edge:
			myVel = (myNextPos - myCurrentPos)/(params.stepSize);
			velocityTable[phenotype] = myVel;
			
			params.log.log(msgchunks: [\velupdate,
					\vel, myVel,
					\pos, myCurrentPos,
				], priority: -1,
				tag: \moving);
			
			phenotype.chromosome = myNextPos;
			controller.updateIndividual(phenotype);
			params.log.log(msgchunks: [\postmove,
					\phenotype, phenotype
				], priority: -1,
				tag: \moving);

			(myCurrentFitness>myBestFitness).if({
				myBestFitness = myCurrentFitness;
				myBestPos = myCurrentPos;
			});
			
			bestKnownPosTable[phenotype] = myBestPos;
			bestKnownFitnessTable[phenotype] = myBestFitness;
		});
		iterations = iterations + 1;
	}
	
	free {
		super.free;
		controller.free;
	}
}
	