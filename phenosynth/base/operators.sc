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
		Library.put(\phenosynth, \nulloperator,
			{|...args|
				"null operator called!".throw;
			}
		);
		Library.put(\phenosynth, \chromosome_fact, \basic,
			{|params|
				params.individualClass.newRandom(params.initialChromosomeSize);
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
				phenotype.chromosome.mean;
			}
		);
		//another test one - solve some trigonometry for fun
		// specifically, sin(3wx\pi/2) = cos(yz\pi)
		// The 2-foo term is about making the term be >0 without a cooker
		Library.put(\phenosynth, \fitness_evals, \scaled_trigonometry,
			{|params, phenotype|
				var a0, a1, a2, a3;
				# a0, a1, a2, a3 = phenotype.chromosome;
				(2 - 
					((
						((a0*a1*pi).cos) -
						((a2*a3*pi*3/2).sin)
					).abs)
				).max(0);
			};
		);
		//another test one - solve some trigonometry for fun
		// specifically, sin(3wx\pi/2) = cos(yz\pi)
		// this needs to be re-scaled
		Library.put(\phenosynth, \fitness_evals, \trigonometry,
			{|params, phenotype|
				var a0, a1, a2, a3;
				# a0, a1, a2, a3 = phenotype.chromosome;
				((
					((a0*a1*pi).cos) -
					((a2*a3*pi*3/2).sin)
				).abs);
			};
		);
		
		/* Fitness processors take the fitnesses of the entire population
		and massage it it*/
		/* This first one does the trivial thing, passing them unchanged. */
		Library.put(\phenosynth, \fitness_cookers, \raw,
			{|params, rawFitnesses|
				rawFitnesses;
			};
		);
		/*return the fitnesses as ordinal ranks.
		Higher raw fitness is higher rank.
		Surprisingly tricky to do this, no?*/
		Library.put(\phenosynth, \fitness_cookers, \ranked,
			{|params, rawFitnesses|
				var newFitnesses, size;
				size = rawFitnesses.size;
				newFitnesses = 0!size;
				((rawFitnesses.order) +++ Array.series(size,0,1)).do(
					{|i|
						newFitnesses[i[0]] = i[1];
				});
				newFitnesses;
			};
		);
		/*return the fitnesses as ordinal ranks.
		Higher raw fitness is lower rank. */
		Library.put(\phenosynth, \fitness_cookers, \reverse_ranked,
			{|params, rawFitnesses|
				var newFitnesses, size;
				size = rawFitnesses.size;
				newFitnesses = 0!size;
				((rawFitnesses.order) +++  Array.series(size,0,1)).do(
					{|i|
						newFitnesses[i[0]] = i[1];
				});
				size - newFitnesses - 1;
			};
		);
		/* if fitness approaches zero for a good result, use this
		It incidentally rescales everything to be in the range 0-1,
		where fitnesss is reported as 1 when it's closest to 1
		and 0 when it's farthest.*/
		Library.put(\phenosynth, \fitness_cookers, \zero_peak,
			{|params, rawFitnesses|
				var cookedFitnesses, fitnessVals, range;
				cookedFitnesses = IdentityDictionary.new;
				
				fitnessVals = rawFitnesses.values.asArray.abs;
				fitnessVals.notEmpty.if({
					var fmax, fmin;
					fmax = fitnessVals.maxItem;
					fmin = fitnessVals.minItem;
					range = [fmax-fmin, 0.001].maxItem;
					rawFitnesses.keysValuesDo({|key,val|
						cookedFitnesses[key] = (range-(val.abs-fmin))/range;
					});
				});
				cookedFitnesses;
			};
		);
		
		/*
		Termination conditions tell us when to stop -
		when we are "close enough" or have run too long
		*/
		Library.put(\phenosynth, \termination_conds, \basic,
			{|params, population, iterations|
				iterations > params.stopIterations;
			}
		);
		
		/*
		Death selectors select which agents to cull.
		*/
		Library.put(\phenosynth, \death_selectors, \byRoulettePerRate,
			{|params, fitnesses|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette
				var hitList, localFitnesses, maxFitness, negFitnesses, meanFitness, rate;
				(fitnesses.size == 0).if({
					"Warning: empty population; no death for now".postln;
					[];
				}, {
					rate = params.deathRate;
					localFitnesses = fitnesses.values.asArray;
					maxFitness = localFitnesses.maxItem;
					negFitnesses = maxFitness - localFitnesses;
					meanFitness = negFitnesses.mean;
					hitList = fitnesses.keys.select({|p|
						((((maxFitness - fitnesses[p])/meanFitness)*rate).coin)
					});
					hitList;
				});
			}
		);
		Library.put(\phenosynth, \death_selectors, \byRoulettePerRateAdultsOnly,
			{|params, fitnesses|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette, in sufficiently old agents
				var hitList, localFitnesses, maxFitness, negFitnesses, meanFitness, localPopulation, rate;
				rate = params.deathRate;
				localPopulation = fitnesses.keys.asArray.select(_.logicalAge>1);
				localFitnesses = localPopulation.collect({|i| fitnesses[i];});
				//[\localPopulation, localPopulation.size, localPopulation, fitnesses].postln;
				(localPopulation.size == 0).if({
					"Warning: no valid candidates; no death for now".postln;
					[];
				}, {
					maxFitness = localFitnesses.maxItem;
					negFitnesses = maxFitness - localFitnesses;
					meanFitness = negFitnesses.mean;
					hitList = localPopulation.select({|p|
						((((maxFitness - fitnesses[p])/meanFitness)*rate).coin)
					});
					hitList;
				});
			}
		);
		//birth selector protocol:
		//return an array of arrays of parents
		Library.put(\phenosynth, \birth_selectors, \byRoulettePerTotal,
			{|params, fitnesses|
				// choose enough proud parents to keep the population constant, by
				// fitness-weighted roulette
				var localPopulation, parentList, localFitnesses, meanFitness, targetBirths;
				(fitnesses.size == 0).if({
					"Warning: empty population; no breeding for now".postln;
					[\emptiness, fitnesses].postln;
					[];
				}, {
					targetBirths = (params.populationSize) - fitnesses.size;
					localPopulation = fitnesses.keys.asArray;
					localFitnesses = localPopulation.collect({|i| fitnesses[i];});
					meanFitness = localFitnesses.mean;
					localFitnesses = localFitnesses / (localFitnesses.sum);
					parentList = targetBirths.collect(
						params.numParents.collect(
							localPopulation.wchoose(localFitnesses)
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