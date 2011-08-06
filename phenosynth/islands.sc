PSIsland {
  //Islands accept populations of individuals, which can be anything
  //responding to the messages \chromosome, \fitness and \identityHash
  var deathSelector;
  var breedSelector;
  var mutator;
  var crossover;
  var initialChromosoneFactory;
  var individualFactory;
  //we keep instance settings in a mutable Environment so that
  //generic function parameters can be passed to mutators, and they may
  //be modified at run-time without defining new functions
  var <>params;
  
  //This is the main state variable
  var <population;
  
  //some default population massaging functions
  //since we can't define naked functions in a classvar, we set these up in 
  //the *defaultOperators method.
  classvar defaultDeathSelector;
  classvar defaultBreedSelector;
  classvar defaultMutator;
  classvar defaultCrossover;
  classvar defaultInitialChromosoneFactory;
  classvar defaultIndividualFactory;
  
  *initClass {
    StartUp.add({
      this.defaultOperators;
    });
  }
  
  // default values for that parameter thing
  // I wish I could do this with a literal instead of a method
  // because overriding is way awkward this way.
  *defaultParams {
    ^(
      \deathRate: 0.1,
      \birthRate: 0.1,
      \maxPopulation: 30,
      \minPopulation: 2,
      \numParents: 2,
      \chromosomeMinLength: 20,
      \crossoverProb: 0.1,
      \individualClass: PSPhenome,
      \mutationRate: 0.1
    );
  }
  
  //where we define the default operators. These are vanilla functions;
  //you might want to mix and match them, after all.
  *defaultOperators {
    defaultDeathSelector = {|params, population|
      PSSelectors.findReapableByRoulette(params, population);
    };
    defaultBreedSelector = {|params, population|
      PSSelectors.findSowableByRoulette(params, population);
    };
    defaultMutator = {|params, chromosome|
      PSMutators.floatPointMutation(
        params,
        chromosome);
    };
    defaultCrossover = {|params, chromosomes|
      //this is a pretty awful crossover.
      PSCrossovers.uniformCrossover(chromosomes);
    };
    defaultInitialChromosoneFactory = {|params|
      params.individualClass.newRandom;
    };
    defaultIndividualFactory = {|params, chromosome|
      params.individualClass.new(chromosome);
    };
  }
  
  *new {|params,
    deathSelector,
    breedSelector,
    mutator,
    crossover,
    initialChromosoneFactory,
    individualFactory|
    ^super.newCopyArgs(
      deathSelector ? defaultDeathSelector,
      breedSelector ? defaultBreedSelector,
      mutator ? defaultMutator,
      crossover ? defaultCrossover,
      initialChromosoneFactory ? defaultInitialChromosoneFactory,
      individualFactory ? defaultIndividualFactory,
      params ? this.defaultParams
    ).init;
  }
  init {
    
  }
}

PSCrossovers {
  *uniformCrossover {|params, chromosomes|
    ^(chromosomes[0].size).collect({|i| chromosomes.slice(nil, i).choose;});
  }
}
PSMutators {
  *floatPointMutation{|params, chromosome|
    var rate;
    var amp=0.5;
    rate = params.mutationRate * (chromosome.size.reciprocal);
    chromosome.do({|val, index|
      (rate.coin).if ({
        chromosome[index] = (val + amp.sum3rand).wrap(0, 1);
      });
    });
    ^chromosome;
  }
}
PSSelectors {
  *findReapableByRoulette {|params, population|
    //choose enough doomed to meet the death rate on average, by fitness-
    // weighted roulette
    var hitList, localFitnesses, negFitnesses, meanFitness, rate;
    rate = params.deathRate;
    localFitnesses = population.collect({|i| i.fitness;});
    //this array operation business fails for empty lists...
    localFitnesses.isEmpty.if({^[]});
    negFitnesses = localFitnesses.reciprocal;
    meanFitness = negFitnesses.mean;
    //["inverting", meanFitness].postln;
    //localFitnesses.postln;
    //negFitnesses.postln;
    hitList = population.select(
      {|i| ((((i.fitness.reciprocal)/meanFitness)*rate).coin)});
    //["hitList", hitList.collect({|i| i.fitness;})].postln;
    ^hitList;
  }
  *findSowableByRoulette {|params, population|
    //choose enough proud parents to meet the birth rate on average, by
    // fitness-weighted roulette
    var hitList, localFitnesses, meanFitness, rate;
    rate = params.deathRate;
    localFitnesses = population.select({|i| i.age>0}).collect({|i| i.fitness;});
    //this array operation business fails for empty lists...
    localFitnesses.isEmpty.if({^[]});
    meanFitness = localFitnesses.mean;
    hitList = population.select(
      {|i| ((((i.fitness)/meanFitness)*rate).coin)});
    //["hitList", hitList.collect({|i| i.fitness;})].postln;
    ^hitList;
  }
}