PSIsland {
	/*Islands manage populations of individuals, which can be anything
	responding to \chromosome*/

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
	classvar <defaultFitnessCooker = #[phenosynth, fitness_cookers, nothing];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, basic];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRate];
	classvar <defaultBirthSelector = #[phenosynth, birth_selectors, byRoulettePerTotal];
	classvar <defaultMutator = #[phenosynth, mutators, floatPointMutation];
	classvar <defaultCrossover = #[phenosynth, crossovers, uniformCrossover];
	//we keep instance settings in a mutable Environment so that
	//generic function parameters can be passed to mutators, and they may
	//be modified at run-time without defining new functions
	var <>params;
	
	//These are the main state variable
	var <population;
	var <rawFitnesses;
	var <cookedFitnesses;
	
	/* this is another state variable. If I got one nore small var like this I'd make it
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
	var <fitnessEvaluator;
	var <fitnessCooker;
	var <terminationCondition;
	
	//var <fitnessPlotWindow;

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
	fitnessCooker_ {|fn|
		fitnessCooker = this.loadFunction(fn);
	}
	terminationCondition_ {|fn|
		terminationCondition = this.loadFunction(fn);
	}
	init {
		population = IdentitySet.new;
		rawFitnesses = IdentityDictionary.new;
		cookedFitnesses = IdentityDictionary.new;
		this.initOperators;
	}
	initOperators {
		this.deathSelector = this.class.defaultDeathSelector;
		this.birthSelector = this.class.defaultBirthSelector;
		this.mutator = this.class.defaultMutator;
		this.crossover = this.class.defaultCrossover;
		this.initialChromosomeFactory = this.class.defaultInitialChromosomeFactory;
		this.individualFactory = this.class.defaultIndividualFactory;
		this.fitnessEvaluator = this.class.defaultFitnessEvaluator;
		this.fitnessCooker = this.class.defaultFitnessCooker;
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
		rawFitnesses.removeAt(phenotype);
		cookedFitnesses.removeAt(phenotype);
	}
	populate {
		params.populationSize.do({
			this.add(initialChromosomeFactory.value(params));
		});
	}
	evaluate {
		population.do({|phenotype|
			this.setFitness(phenotype, fitnessEvaluator.value(params, phenotype));
			phenotype.incAge;
		});
		cookedFitnesses = fitnessCooker.value(params, rawFitnesses);
	}
	setFitness {|phenotype, value|
		rawFitnesses[phenotype] = value;
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
		toCull = deathSelector.value(params, cookedFitnesses);
		//[\culling, toCull].postln;
		//beforeFitness = cookedFitnesses.values.asArray.mean;
		this.cull(toCull);
		//afterFitness = cookedFitnesses.values.asArray.mean;
		//[\fitness_delta, afterFitness - beforeFitness].postln;
		toBreed = birthSelector.value(params, cookedFitnesses);
		//[\parents, toBreed].postln;
		this.breed(toBreed);
		iterations = iterations + 1;
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
	rankedPopulation {
		//return all population that have a fitness, ranked in descending order thereof.
		//Individuals that do not yet have a fitness are not returned
		^population.selectAs(
			{|i| cookedFitnesses[i].notNil}, Array
		).sort({|a, b| cookedFitnesses[a] > cookedFitnesses[b] });
	}
	plotFitness {|parent, raw=false|
		var orderedFitnesses, orderedPopulation;
		orderedPopulation = population.asArray;
		orderedPopulation.sort({ arg a, b; a.hash < b.hash });
		raw.if(
			{
				orderedFitnesses = orderedPopulation.collect({|i| rawFitnesses[i]}).select(_.notNil);
			}, {
				orderedFitnesses = orderedPopulation.collect({|i| cookedFitnesses[i]}).select(_.notNil);
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
	
	classvar <defaultFitnessEvaluator = #[phenosynth, nulloperator];
	classvar <defaultDeathSelector = #[phenosynth, death_selectors, byRoulettePerRateAdultsOnly];

	*defaultParams {
		var defParams = super.defaultParams;
		defParams.populationSize = 100;
		^defParams;
	}	
	*new {|params|
		params.pollPeriod ?? {
			params = params.copy;
			params.pollPeriod = 1;
		}
		^super.new(params).init;
	}
	init {
		^super.init;
	}
	evaluate {
		//No individual fitness updating; (they are updated for us)
		// but allow group fitness alterations
		cookedFitnesses = fitnessCooker.value(params, rawFitnesses);
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
