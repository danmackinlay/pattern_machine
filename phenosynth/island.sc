PSIsland {
	/*Islands manage populations of individuals, which can be anything
	responding to \chromosome and \fitness.*/

	/*
	where we define the default operators. These are, in general, vanilla
	functions or paths to Library functions that will be cast to Library
	functions at run time, in the initOperators method.
	
	Since we can't define naked functions in a classvar, these particular ones
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
	var <>deathSelector;
	var <>birthSelector;
	var <>mutator;
	var <>crossover;
	var <>initialChromosomeFactory;
	var <>individualFactory;
	var <>fitnessEvaluator;
	var <>terminationCondition;


	// default values for that parameter thing
	// I wish I could do this with a literal instead of a method
	// because overriding is way awkward this way.
	*defaultParams {
		^(
			\deathRate: 0.1,
			\populationSize: 100,
			\numParents: 2,
			\chromosomeMinLength: 20,
			\crossoverProb: 1,
			\individualClass: PSPhenotype,
			\mutationProb: 0.1,
			\mutationSize: 0.1,
			\stopIterations: 10000
		);
	}
	*new {|params|
		^super.newCopyArgs(
			this.defaultParams.updatedFrom(params);
		).init;
	}
	init {
		this.initOperators;
		population = List.new;
	}
	initOperators {
		deathSelector = this.loadFunction(this.class.defaultDeathSelector);
		birthSelector = this.loadFunction(this.class.defaultBirthSelector);
		mutator = this.loadFunction(this.class.defaultMutator);
		crossover = this.loadFunction(this.class.defaultCrossover);
		initialChromosomeFactory = this.loadFunction(this.class.defaultInitialChromosomeFactory);
		individualFactory = this.loadFunction(this.class.defaultIndividualFactory);
		fitnessEvaluator = this.loadFunction(this.class.defaultFitnessEvaluator);
		terminationCondition = this.loadFunction(this.class.defaultTerminationCondition);
	}
	loadFunction {|nameOrFunction|
		/* we have a method here fo two reasons:
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
			fitnessEvaluator.value(params, phenotype);
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
		iterator = this.iterator;
		while {iterator.next } {
			//action happens in iterator
		};
	}
	free {
		playing = false;
	}
	iterator {
		/* Return a routine that does the work of triggering the work we want as
			long as things are supposed to be moving along. */
		^Routine.new({while(
			{
				(terminationCondition.value(
					params, population, iterations
				).not) && 
				playing 
			},
			{
				this.tend;
				[\iterations, iterations, this.fitnesses.mean].postln;
				true.yield;
			};
		);
		false.yield;}, stackSize: 1024);//seems to overflow easily?
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
	var <pollPeriod;
	var <worker;
	var clock;
	
	classvar defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];
	
	*new {| params, pollPeriod=1|
		//Why is pollPeriod not part of params?
		^super.new(params).init(pollPeriod);
	}
	init {|newPollPeriod|
		pollPeriod = newPollPeriod;
		^super.init;
	}
	evaluate {
		//no-op in this class; they are realtime self-updating
	}
	play {
		/*note this does not call parent. If you can find a way of making this do
		the right thing with the generated routine while still caling the parent
		method, more power to you. Submit a patch. */
		var iterator;
		this.populate;
		clock = TempoClock.new(pollPeriod.reciprocal, 1);
		iterator = this.iterator;
		playing = true;
		worker = Routine.new({
			while {iterator.next;}
				{ 
					1.yield;
				}
		}).play(clock);
	}
	free {
		super.free;
		worker.free;
		clock.stop;
	}
}

//Things specific to my diabolical schemes - i.e. phenotypic selection on swarming agents

PSSynthSwarmIsland : PSRealTimeIsland {
	/* PSIsland that plays agents through a (presumably server?) controller abstraction*/
	
	classvar <defaultCrossover = #[\phenosynth, \crossovers, \meanCrossover];
	
	var <controller;
	
	*defaultParams {
		var defParams = super.defaultParams;
		defParams.individualClass = PSEarSwarmPhenotype;
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
	play {
		controller.play;
		super.play;
	}
	free {
		super.free;
		controller.free;
	}
}
