PSIsland {
	/*Islands manage populations of individuals, which can be anything
	responding to \chromosome and \fitness.*/

	/*
	where we define the default operators. These are, in general, vanilla
	functions or paths to Library functions that will be cast to Library
	functions at run time, in the initOperators method.
	
	Since we can't define naked functions in a classvar, these *particular* ones
	are all Library Paths.
	*/
	
	classvar <defaultInitialChromosomeFactory = #[phenosynth, chromosome_fact, basic];
	classvar <defaultIndividualFactory = #[phenosynth, individual_fact, basic];
	classvar <defaultFitnessEvaluator = #[phenosynth, fitness_evals, chromosomemean];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, basic];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRate];
	classvar <defaultBirthSelector = #[phenosynth, birth_selectors, byRoulettePerTotal];
	classvar <defaultMutator = #[phenosynth, mutators, floatPointMutation];
	classvar <defaultCrossover = #[phenosynth, crossovers, uniformCrossover];
	//we keep instance settings in a mutable Environment so that
	//generic function parameters can be passed to mutators, and they may
	//be modified at run-time without defining new functions
	var <>params;
	
	//This is the main state variable
	var <population;
	
	// this is another state variable. If I got one more I'd make it
	// a state *dictionary*
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
	var <fitnessEvaluator;
	var <terminationCondition;

	// default values for that parameter thing
	// I wish I could do this with a literal instead of a method
	// because overriding is way awkward this way.
	*defaultParams {
		^(
			\deathRate: 0.1,
			\populationSize: 100,
			\numParents: 2,
			\initialChromosomeSize: 1,
			\crossoverProb: 1,
			\individualClass: PSPhenotype,
			\mutationProb: 0.1,
			\mutationSize: 0.1,
			\stopIterations: 1000
		);
	}
	*new {|params|
		^super.newCopyArgs(
			this.defaultParams.updatedFrom(params ? Event.new);
		).init;
	}
	deathSelector_ {|fn|
		deathSelector = this.loadFunction(fn);
	}
	birthSelector_ {|fn|
		birthSelector = this.loadFunction(fn);
	}
	mutator_ {|fn|
		mutator = this.loadFunction(fn);
	}
	crossover_ {|fn|
		crossover = this.loadFunction(fn);
	}
	initialChromosomeFactory_ {|fn|
		initialChromosomeFactory = this.loadFunction(fn);
	}
	individualFactory_ {|fn|
		individualFactory = this.loadFunction(fn);
	}
	fitnessEvaluator_ {|fn|
		fitnessEvaluator = this.loadFunction(fn);
	}
	terminationCondition_ {|fn|
		terminationCondition = this.loadFunction(fn);
	}
	init {
		this.initOperators;
		population = IdentitySet.new;
	}
	initOperators {
		this.deathSelector = this.class.defaultDeathSelector;
		this.birthSelector = this.class.defaultBirthSelector;
		this.mutator = this.class.defaultMutator;
		this.crossover = this.class.defaultCrossover;
		this.initialChromosomeFactory = this.class.defaultInitialChromosomeFactory;
		this.individualFactory = this.class.defaultIndividualFactory;
		this.fitnessEvaluator = this.class.defaultFitnessEvaluator;
		this.terminationCondition = this.class.defaultTerminationCondition;
	}
	loadFunction {|nameOrFunction|
		/* we have a method here for two reasons:
		1. it allows us to transparently pass through actual functions, but load
			other things from the Library
		2. to force a test for missing library names, or it's hard to track what
			went wrong. (Because nil is callable(!))
		*/
		var candidate;
		nameOrFunction.isFunction.if(
			{^nameOrFunction},
			{
				candidate = Library.atList(nameOrFunction);
				candidate.isNil.if({
					("Nothing found at %".format(nameOrFunction.cs)).throw;
				});
				candidate.isFunction.not.if({
					("Non-function found at % (%)".format(
						nameOrFunction.cs, candidate.cs)
				).throw;
				});
				^candidate;
			}
		);
	}
	add {|phenotype|
		population.add(phenotype);
	}
	remove {|phenotype|
		population.remove(phenotype);
	}
	populate {
		params.populationSize.do({
			this.add(initialChromosomeFactory.value(params));
		});
	}
	evaluate {
		population.do({|phenotype|
			phenotype.fitness = fitnessEvaluator.value(params, phenotype);
			phenotype.incAge;
		});
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
		toCull = deathSelector.value(params, population);
		//[\culling, toCull].postln;
		this.cull(toCull);
		//afterFitness = population.collect(_.fitness).mean;
		//[\fitness_delta, afterFitness - beforeFitness].postln;
		toBreed = birthSelector.value(params, population);
		this.breed(toBreed);
		iterations = iterations + 1;
	}
	fitnesses {
		^population.collect(_.fitness);
	}
	play {
		//The fire button. trigger this, and the simulation will run until it is bored
		var iterator;
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
}

PSRealTimeIsland : PSIsland {
	/* instead of checking my agents for fitness, I expect them to update
	themselves. I poll them at a defined interval to do tending.*/
	var <worker;
	var clock;
	
	classvar <defaultFitnessEvaluator = #[phenosynth, nulloperator];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];

	*defaultParams {
		var defParams = super.defaultParams;
		defParams.pollPeriod = 1;
		defParams.populationSize = 100;
		^defParams;
	}	
	*new {|params|
		//Why is pollPeriod not part of params?
		^super.new(params).init;
	}
	init {
		^super.init;
	}
	evaluate {
		//no-op in this class; they are realtime self-updating
	}
	play {
		/*note this does not call parent. */
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
		worker.free;
		clock.stop;
	}
}

PSControllerIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a (presumably server?) controller
	 * abstraction */
	
	var <controller;
	
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
		controller.play;
		super.play;
	}
	free {
		super.free;
		controller.free;
	}
}
