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
				params.individualFactory.newRandom(params.initialChromosomeSize);
			}
		);
		Library.put(\phenosynth, \individual_fact, \basic,
			{|params, chromosome|
				params.individualFactory.new(chromosome);
			}
		);
		//not practical, just a sanity check - return the mean of the chromosome
		Library.put(\phenosynth, \score_evals, \chromosomemean,
			{|params, phenotype|
				phenotype.chromosome.mean;
			}
		);
		//another test one - solve some trigonometry for fun
		// specifically, sin(3wx\pi/2) = cos(yz\pi)
		// The 2-foo term is about making the term be >0 without a cooker
		Library.put(\phenosynth, \score_evals, \scaled_trigonometry,
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
		Library.put(\phenosynth, \score_evals, \trigonometry,
			{|params, phenotype|
				var a0, a1, a2, a3;
				# a0, a1, a2, a3 = phenotype.chromosome;
				((
					((a0*a1*pi).cos) -
					((a2*a3*pi*3/2).sin)
				).abs);
			};
		);
		
		/* Score cookers take the scores of the entire population
		and massage them into fitnesses */
		/* This first one does the trivial thing, passing them unchanged. */
		Library.put(\phenosynth, \score_cookers, \raw,
			{|params, rawScores|
				rawScores;
			};
		);
		/*return the scores as ordinal fitness ranks.
		Lower raw score is higher rank fitness.
		Surprisingly tricky to do this, no?*/
		Library.put(\phenosynth, \score_cookers, \reverse_ranked,
			{|params, rawScores|
				var fitnessOrder, size, cookedFitnesses;
				cookedFitnesses = IdentityDictionary.new;
				size = rawScores.size;
				(size>0).if({
					fitnessOrder = Array.newClear(size);
					rawScores.keysValuesDo({|key, val, i|
						fitnessOrder[i] = (id:key, fitness:val);
					});
					fitnessOrder.sortBy(\fitness);
					fitnessOrder.do({|elem, i|
						cookedFitnesses[elem[\id]] = size-i;
					});
				});
				cookedFitnesses;
			};
		);

		/*return the scores as ordinal fitness ranks.
		Higher raw score is higher rank. */
		Library.put(\phenosynth, \score_cookers, \ranked,
			{|params, rawScores|
				var fitnessOrder, size, cookedFitnesses;
				cookedFitnesses = IdentityDictionary.new;
				size = rawScores.size;
				(size>0).if({
					fitnessOrder = Array.newClear(size);
					rawScores.keysValuesDo({|key, val, i|
						fitnessOrder[i] = (id:key, fitness:val);
					});
					fitnessOrder.sortBy(\fitness);
					fitnessOrder.do({|elem, i|
						cookedFitnesses[elem[\id]] = i;
					});
				});
				cookedFitnesses;
			};
		);
		/* if score approaches zero for a good result (e.g. a
		distance metric for some matching process), use this.
		It incidentally rescales everything to be in the range 0-1,
		where fitnesss is reported as 1 when it's closest to 1
		and 0 when farthest.*/
		Library.put(\phenosynth, \score_cookers, \zero_peak,
			{|params, rawScores|
				var cookedFitnesses, normedScores, range;
				cookedFitnesses = IdentityDictionary.new;
				
				normedScores = rawScores.values.asArray.abs;
				normedScores.notEmpty.if({
					var fmax, fmin;
					fmax = normedScores.maxItem;
					fmin = normedScores.minItem;
					range = [fmax-fmin, 0.001].maxItem;
					rawScores.keysValuesDo({|key,val|
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
			{|params, fitnessMap|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette
				var hitList, localFitnesses, localPopulation, meanFitness, rate;
				(fitnessMap.size == 0).if({
					"Warning: empty population; no death for now".postln;
					[];
				}, {
					//notice we do our rate calculations based on chance of survival
					//the maths here is slighly flakey. Given a set death rate, and a fitness-weighted rate
					//how do we make this fly properly? Hot Poisson/exp distro action.
					//anyway, for low rates they all converge.
					localPopulation = fitnessMap.keys;
					rate = params.deathRate;
					meanFitness = localFitnesses.mean;
					hitList = localPopulation.select({|p|
						(1-((fitnessMap[p]/meanFitness)*rate)).coin.not;
					});
					hitList;
				});
			}
		);
		Library.put(\phenosynth, \death_selectors, \byRoulettePerRateAdultsOnly,
			{|params, fitnessMap|
				//choose enough doomed to meet the death rate on average, by fitness-
				// weighted roulette, in sufficiently old agents
				var hitList, localFitnesses, meanFitness, localPopulation, rate;
				localPopulation = fitnessMap.keys.asArray.select(_.logicalAge>1);
				localFitnesses = localPopulation.collect({|i| fitnessMap[i];});
				//[\localPopulation, localPopulation.size, localPopulation, fitnessMap].postln;
				(localPopulation.size == 0).if({
					"Warning: no valid candidates; no death for now".postln;
					[];
				}, {
					//see comments at #[phenosynth, death_selectors, byRoulettePerRate]
					rate = params.deathRate;
					meanFitness = localFitnesses.mean;
					hitList = localPopulation.select({|p|
						params.log.log(msgchunks: [\localinvrate, (1-((fitnessMap[p]/meanFitness)*rate))], tag: \selection, priority: -1);
						(1-((fitnessMap[p]/meanFitness)*rate)).coin.not;
					});
					params.log.log(msgchunks: [\selectionbidnez, rate, meanFitness] ++ localFitnesses, tag: \selection, priority: -1);
					hitList;
				});
			}
		);
		//birth selector protocol:
		//return an array of arrays of parents
		Library.put(\phenosynth, \birth_selectors, \byRoulettePerTotal,
			{|params, fitnessMap|
				// choose enough proud parents to keep the population constant, by
				// fitness-weighted roulette
				var localPopulation, parentList, localFitnesses, meanFitness, targetBirths;
				(fitnessMap.size == 0).if({
					"Warning: empty population; no breeding for now".postln;
					[\emptiness, fitnessMap].postln;
					[];
				}, {
					targetBirths = (params.populationSize) - fitnessMap.size;
					localPopulation = fitnessMap.keys.asArray;
					localFitnesses = localPopulation.collect({|i| fitnessMap[i];});
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
		/* simulate a bit-vector mutation in a flaoting point variable.
		This ignore mutation amplitude and uses only the rate to determine how many
		bits to flip. 0 or one bits flipped per float, out of laziness.*/
		Library.put(\phenosynth, \mutators, \pseudoFloatBitflip,
			{|params, chromosome|
				var rate = params.mutationProb;
				chromosome.do({|val, index|
					(rate.coin).if ({
						//exponentially distributed mutations to mimic flipping bits in
						//24-bit-mantissa binary floats. lazy, inefficient, effective.
						chromosome[index] = (val +
							(2.0 ** (24.0.rand.neg)) *
							(2.rand*2-1)
						).wrap(0, 1);
					});
				});
				chromosome;
			}
		);
		/* Classic evolution-strategy-style Gaussian mutation */
		Library.put(\phenosynth, \mutators, \gaussianPerturb,
			{|params, chromosome|
				var rate = params.mutationProb;
				var amp = params.mutationSize;
				chromosome.do({|val, index|
					(rate.coin).if ({
						chromosome[index] = (val.gauss(amp)).wrap(0, 1);
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