/*
genetic operators - mutators, selectors, crossovers....
*/
PSOperators {
	*initClass {
		StartUp.add({
			this.loadOperators;
		});
	}
	*loadOperators {
		Library.put(\phenosynth, \chromosome_fact, \basic,
			{|params|
				params.individualClass.newRandom;
			}
		);
		Library.put(\phenosynth, \individual_fact, \basic,
			{|params, chromosome|
				params.individualClass.new(chromosome);
			}
		);
		//not practical, just a sanity check - return the mean of the chromosome
		Library.put(\phenosynth, \fitness_evals, \chromosomemean,
			{|params, phenotype|
					phenotype.fitness = phenotype.chromosome.mean;
			}
		);
		Library.put(\phenosynth, \termination_conds, \basic,
			{|params, population, iterations|
				iterations > params.stopIterations;
			}
		);
		Library.put(\phenosynth, \death_selectors, \byRoulettePerRate,
			{|params, population|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette
				var hitList, localFitnesses, maxFitness, negFitnesses, meanFitness, rate;
				(population.size == 0).if({
					"Warning: empty population; no death for now".postln;
					[];
				}, {
					rate = params.deathRate;
					localFitnesses = population.collect({|i| i.fitness;});
					maxFitness = localFitnesses.maxItem;
					negFitnesses = maxFitness - localFitnesses;
					meanFitness = negFitnesses.mean;
					hitList = population.select(
						{|i| ((((maxFitness - i.fitness)/meanFitness)*rate).coin)}
					);
					hitList;
				});
			}
		);
		Library.put(\phenosynth, \death_selectors, \byRoulettePerRateAdultsOnly,
			{|params, population|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette, in sufficiently old agents
				var hitList, localFitnesses, maxFitness, negFitnesses, meanFitness, localPopulation, rate;
				rate = params.deathRate;
				localPopulation = population.select(_.logicalAge>1);
				localFitnesses = localPopulation.collect(_.fitness);
				//[\localPopulation, localPopulation.size, localPopulation, population].postln;
				(localPopulation.size == 0).if({
					"Warning: no valid candidates; no death for now".postln;
					[];
				}, {
					maxFitness = localFitnesses.maxItem;
					negFitnesses = maxFitness - localFitnesses;
					meanFitness = negFitnesses.mean;
					hitList = localPopulation.select(
						((((maxFitness - _.fitness)/meanFitness)*rate).coin)
					);
					hitList;
				});
			}
		);
		//birth selector protocol:
		//return an array of arrays of parents
		Library.put(\phenosynth, \birth_selectors, \byRoulettePerTotal,
			{|params, population|
				// choose enough proud parents to keep the population constant, by
				// fitness-weighted roulette
				var parentList, localFitnesses, meanFitness, targetBirths;
				(population.size == 0).if({
					"Warning: empty population; no breeding for now".postln;
					[];
				}, {
					targetBirths = (params.population) - population.size;
					localFitnesses = population.collect({|i| i.fitness;});
					meanFitness = localFitnesses.mean;
					localFitnesses = localFitnesses / (localFitnesses.sum);
					parentList = targetBirths.collect(
						params.numParents.collect(
							population.wchoose(localFitnesses)
						)
					);
					parentList;
				});
			}
		);
		Library.put(\phenosynth, \mutators, \floatPointMutation,
			{|params, chromosome|
				var rate;
				var amp = params.mutationSize;
				rate = params.mutationProb * (chromosome.size.reciprocal);
				chromosome.do({|val, index|
					(rate.coin).if ({
						//exponentially distributed mutations to mimic flipping bits in 
						//32 bit binary floats. lazy, inefficient, effective.
						chromosome[index] = (val + 
							(2.0 ** (32.0.rand.neg)) *
							(2.rand*2-1)
						).wrap(0, 1);
					});
				});
				chromosome;
			}
		);
		Library.put(\phenosynth, \crossovers, \uniformCrossover,
			{|params, chromosomes|
				//an awful crossover, useful for only the most boneheaded of problems
				(chromosomes[0].size).collect(
					{|i| chromosomes.slice(nil, i).choose;}
				);
			}
		);
		Library.put(\phenosynth, \crossovers, \meanCrossover,
			{|params, chromosomes|
				//Useful for small problems with short float-based chromosomes - 
				// chooses either number or a mean of two adjacent ones (diploid-lite)
				var size = (chromosomes.size*2+1);
				chromosomes.flop.collect(_.blendAt(size.rand/2));
			}
		);
	}
}