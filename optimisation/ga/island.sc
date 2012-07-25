PSIsland {
	/*Islands manage populations of individuals, which can be anything
	responding to \chromosome */

	/*
	where we define the default operators. These are, in general, vanilla
	functions or paths to Library functions that will be cast to Library
	functions at run time, in the initOperators method.

	Since we can't define naked functions in a classvar, these *particular* ones
	are all Library Paths.
	*/

	classvar <defaultInitialChromosomeFactory = #[phenosynth, chromosome_fact, basic];
	classvar <defaultIndividualFactory = #[phenosynth, individual_fact, defer_to_constructor];
	classvar <defaultScoreEvaluator = #[phenosynth, score_evals, chromosomemean];
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, raw];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, basic];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRate];
	classvar <defaultBirthSelector = #[phenosynth, birth_selectors, byRoulettePerTotal];
	classvar <defaultMutator = #[phenosynth, mutators, gaussianPerturb];
	classvar <defaultCrossover = #[phenosynth, crossovers, uniformCrossover];
	//we keep instance settings in a mutable Environment so that
	//generic function parameters can be passed to mutators, and they may
	//be modified at run-time without defining new functions
	var <>params;

	//These are the main state variables
	var <population;
	var <rawScoreMap;
	var <cookedFitnessMap;

	/* this is another state variable. If I got one more small var like this I'd make it
	a state *dictionary* */
	var <iterations = 0;

	//flag to stop iterator gracefuly.
	var playing = false;

	/*
	Here are the variables that hold the operator functions.
	Paths are coerced to functions at instantiation time to avoid problems with
	not knowing when the Library gets filled.
	*/
	var <deathSelector;
	var <birthSelector;
	var <mutator;
	var <crossover;
	var <initialChromosomeFactory;
	var <individualFactory;
	var <scoreEvaluator;
	var <scoreCooker;
	var <terminationCondition;
	//var <fitnessPlotWindow;

	// default values for that parameter thing
	// I wish I could do this with a literal instead of a method
	// because overriding is way awkward this way.
	*defaultParams {
		^(
			\deathRate: 0.3,
			\populationSize: 100,
			\numParents: 2,
			\initialChromosomeSize: 1,
			\crossoverProb: 1,
			\individualConstructor: PSPhenotype,
			\mutationProb: 0.1,
			\mutationSize: 0.1,
			\stopIterations: 1000,
			\log: NullLogger.new
		);
	}
	*new {|params|
		var thisNew = super.newCopyArgs(
			this.defaultParams.updatedFrom(params ? Event.new)
		).init;
		^thisNew;
	}
	deathSelector_ {|fn|
		deathSelector = LoadLibraryFunction(fn);
	}
	birthSelector_ {|fn|
		birthSelector = LoadLibraryFunction(fn);
	}
	mutator_ {|fn|
		mutator = LoadLibraryFunction(fn);
	}
	crossover_ {|fn|
		crossover = LoadLibraryFunction(fn);
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
		population = IdentitySet.new(1000);
		rawScoreMap = IdentityDictionary.new(1000);
		cookedFitnessMap = IdentityDictionary.new(1000);
		this.initOperators;
	}
	initOperators {
		this.deathSelector = this.class.defaultDeathSelector;
		this.birthSelector = this.class.defaultBirthSelector;
		this.mutator = this.class.defaultMutator;
		this.crossover = this.class.defaultCrossover;
		this.initialChromosomeFactory = this.class.defaultInitialChromosomeFactory;
		this.individualFactory = this.class.defaultIndividualFactory;
		this.scoreEvaluator = this.class.defaultScoreEvaluator;
		this.scoreCooker = this.class.defaultScoreCooker;
		this.terminationCondition = this.class.defaultTerminationCondition;
	}
	add {|phenotype|
		population.add(phenotype);
	}
	remove {|phenotype|
		population.remove(phenotype);
		rawScoreMap.removeAt(phenotype);
		cookedFitnessMap.removeAt(phenotype);
	}
	populate {
		params.populationSize.do({
			this.add(individualFactory.value(params, 
				initialChromosomeFactory.value(params)));
		});
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
	breed {|parentLists|
		parentLists.do({|parents|
			this.breedParents(parents);
		});
	}
	breedParents {|individuals|
		//take a nested list of parents and turn them in to new population.
		var newChromosome;
		params.crossoverProb.coin.if({
			newChromosome = crossover.value(
				params,
				individuals.collect({|i| i.chromosome;})
			);
		}, {
			newChromosome = individuals.choose.chromosome.copy;
		});
		newChromosome = mutator.value(params, newChromosome);
		this.add(individualFactory.value(params, newChromosome));
	}
	cull {|individuals|
		//take a list of the damned and kill them
		individuals.do({|i| this.remove(i);});
	}
	tend {
		// walk the population, doing all the things that GAs do.
		// this is a synchronous thing per default; if you want to do it
		// incrementally, that's your bag.
		var toCull, toBreed;
		var beforeFitness, afterFitness;
		this.evaluate;
		toCull = deathSelector.value(params, cookedFitnessMap);
		params.log.log(msgchunks: [\culling] ++ toCull, tag: \selection);
		beforeFitness = cookedFitnessMap.values.asArray.mean;
		this.cull(toCull);
		afterFitness = cookedFitnessMap.values.asArray.mean;
		params.log.log(msgchunks: [\fitness_delta, afterFitness - beforeFitness], tag: \selection);
		toBreed = birthSelector.value(params, cookedFitnessMap);
		//[\parents, toBreed].postln;
		this.breed(toBreed);
		iterations = iterations + 1;
	}
	play {
		//The fire button. trigger this, and the simulation will run until it is bored
		this.populate;
		playing = true;
		while(
			{(terminationCondition.value(
				params, population, iterations
				).not) &&
				playing},
			{
				this.tend;
			}
		);
	}
	free {
		playing = false;
	}
	reset {
		this.cull(population);
		this.populate;
		iterations = 0;
	}
	rankedPopulation {
		//return all population that have a fitness, ranked in descending order thereof.
		//Individuals that do not yet have a fitness are not returned
		^population.selectAs(
			{|i| cookedFitnessMap[i].notNil}, Array
		).sort({|a, b| cookedFitnessMap[a] > cookedFitnessMap[b] });
	}
	plotFitness {|parent, raw=false|
		var orderedFitnesses, orderedPopulation;
		orderedPopulation = population.asArray;
		orderedPopulation.sort({ arg a, b; a.hash < b.hash });
		raw.if(
			{
				orderedFitnesses = orderedPopulation.collect({|i| rawScoreMap[i]}).select(_.notNil);
			}, {
				orderedFitnesses = orderedPopulation.collect({|i| cookedFitnessMap[i]}).select(_.notNil);
			}
		);
		//fitnessPlotWindow = orderedFitnesses.plot(parent:parent ? fitnessPlotWindow).parent;
		orderedFitnesses.plot();
	}
}

PSRealTimeIsland : PSIsland {
	/* instead of checking my agents for fitness, I expect them to update
	themselves. I poll them at a defined interval to do tending.*/
	var <worker;
	var clock;

	classvar <defaultScoreEvaluator = #[phenosynth, nulloperator];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];

	*defaultParams {
		var defParams = super.defaultParams;
		defParams.populationSize = 40;
		^defParams;
	}
	*new {|params|
		params.clockRate ?? {
			params = params.copy;
			params.clockRate = 1;
		}
		^super.new(params).init;
	}
	init {
		^super.init;
	}
	evaluate {
		//No individual fitness updating; (they are updated for us)
		// but allow group fitness alterations
		cookedFitnessMap = scoreCooker.value(params, rawScoreMap);
	}
	play {
		/*note this does not call parent. */
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
	free {
		super.free;
		worker.free;
		clock.stop;
	}
}
