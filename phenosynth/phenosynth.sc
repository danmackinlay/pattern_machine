/*
Phenosynth: Classes for phenotypic selection of Instrs

NOTES:

* Note that Instr loading is buggy - see http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Instr-calling-Crashes-SC-td4165267.html

  * you might want to use HJH's Instr.loadAll; workaround.
  
TODO:

* Handle "free controls", values that are passed in live by the user. (esp for
  triggers)
  
  * alter chromosome if Specs are changed through UI or any other means, using
    all that Dependent business

* Give the faintest of indications that I do care about tests
* work out a better way to handle non-chromosome'd arguments. right now I
  handle, e.g. SampleSpecs by passing in a voxDefaults array, and triggers by
  introspecting a trigger array. But this is feels ugly compared to wrapping
  an Instr in a function and specifying the missing arguments by lexical
  closure. At the least I could provide lists of specs for each of the
  evolved, free, fixed and trigger parameters, and provide the usual accessors
  to each. (Compare static, fixed and control specs)
* user EnvelopedPlayer to make this release nicely instead of Triggers.
* allow custom evolvability mappings and starting chromosome.
* I've just noticed that MCLD has been facing the same problem and made
  classes similar in spirit to mine, as regards selecting the phenotypes
  rather than genotypes, as the NLTK does:
  http://www.mcld.co.uk/supercollider/ - see also https://github.com/howthebodyworks/MCLD_Genetic
* do free/cleanup logic
* normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
* less arbitrary immigration


* Urgent

  * LFOs
  * give fitness more accumulatey flavour using Integrator
  * give lifespans using the exponential distribution \lambda \e ^-\lambda \e
  * TODO: scale birthRate and deathRate so that they fit eventual fitness
  * reseed population when they all die
  * better aging calculations
  * sort out he interactions of all these differet tick rates and periods.
  * work out why negFitness it can explode when population gets to 2 or less.
  * space out births, since that seems to stop exploding fitnesses.

CREDITS:
Thanks to Martin Marier and Crucial Felix for tips that make this go, and
James Nichols for the peer pressure to do it.
*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr. You would have one of
  these for each population, as a rule.*/
  var <voxInstr, <voxDefaults, <listenInstrName, <listenExtraArgs, <sourceGroup, <outBus, <numChannels, <>phenoClass, <chromosomeMap, <triggers, <listenInstr, <evalPeriod, <voxGroup;
  classvar <defaultVoxInstr="phenosynth.vox.default";
  classvar <defaultListenInstr="phenosynth.listeners.default";

  *new { |voxName, voxDefaults, listenInstrName, listenExtraArgs, sourceGroup, outBus, numChannels, phenoClass|
    //voxName - name, or Instr, that will be source
    //voxDefault - array of default args to voxName
    //listenInstrName, listenExtraArgs - like voxName, but for listening Instr
    //sourceGroup - a group that we must come after (Should we jsut supply the group to be in?)
    ^super.newCopyArgs(
      (voxName ? Genosynth.defaultVoxInstr).asInstr,
      (voxDefaults ? []),
      (listenInstrName ? Genosynth.defaultListenInstr),
      (listenExtraArgs ? []),
      sourceGroup,
      (outBus ? 0),
      (numChannels ? 1),
      (phenoClass ? ListenPhenosynth)).init;
  }
  init {
    chromosomeMap = this.class.getChromosomeMap(voxInstr);
    // pad voxDefaults out to equal number of args
    voxDefaults = voxDefaults.extend(voxInstr.specs.size, nil);
    triggers = this.class.getTriggers(voxInstr);
    /*We give default values to any triggers without a one, or they
    get saddled with an inconvenient BeatClockPlayer*/
    triggers.do({|trigIndex, i| (voxDefaults[trigIndex].isNil).if(
      {voxDefaults[trigIndex] = 1.0;})
    });
  }
  play {
    voxGroup = Group.new(sourceGroup, addAction: \addAfter);
  }
  spawnNaked { |chromosome|
    //just return the phenosynth itself, without listeners
    ^Phenosynth.new(this, voxInstr, voxDefaults, chromosomeMap, triggers, chromosome);
  }
  spawn { |chromosome|
    //return a listened phenosynth
    ^phenoClass.new(this, voxInstr, voxDefaults, chromosomeMap, triggers, listenInstrName, evalPeriod, listenExtraArgs, chromosome);
  }
  newChromosome {
    ^{1.0.rand}.dup(chromosomeMap.size);
  }
  *getChromosomeMap {|newInstr|
    /*use this to work out how to map the chromosome array to synth values,
    ignoring any fixed values, sampleSpecs, or any other kind of
    NonControlSpec
    TODO: Work out how to do this with duck typing.*/
    ^newInstr.specs.indicesSuchThat({|item, i|
      (item.isKindOf(NonControlSpec).not);});
  }
  *getTriggers {|newInstr|
    /*The other input type we might care about is a trigger. I don't know why
    you'd want more than one, but it's more symmetrical if we assume a list,
    so ...*/
    ^newInstr.specs.indicesSuchThat({|item, i|
      item.isKindOf(TrigSpec)});
  }
}

Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should
  be an inner class of GenoSynth, really, but SC doesn't namespace in that
  way.*/
  var <genosynth, <voxInstr, <voxDefaults, <chromosomeMap, <triggers, <voxPatch;
  var <chromosome = nil;
  *new {|genosynth, voxInstr, voxDefaults, chromosomeMap, triggers, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, voxInstr, voxDefaults, chromosomeMap, triggers).init(chromosome);
  }
  init {|chromosome|
    this.createPatch;
    this.chromosome_(chromosome);
  }
  createPatch {
    voxPatch = Patch.new(voxInstr, voxDefaults);
  }
  chromosome_ {|newChromosome|
    /* do this in a setter to allow param update */
    newChromosome.isNil.if({
      newChromosome = genosynth.newChromosome;
    });
    chromosome = newChromosome;
    chromosomeMap.do(
      {|specIdx, chromIdx|
        voxPatch.set(
          specIdx,
          voxPatch.specAt(specIdx).map(chromosome[chromIdx])
        );
      }
    );
  }
  asVals {
    ^voxPatch.args.collect({|a| a.value;});
  }
  trigger {
/*    triggers.do({|item, i| 
      voxPatch.set(item, 1);});
*/  }
  play {
    genosynth.play;
    voxPatch.play(group: genosynth.voxGroup);
    this.trigger();
  }
  free {
    voxPatch.free;
  }
}

ListenPhenosynth : Phenosynth {
  var <listenInstrName;
  var <listenExtraArgs;
  var <evalPeriod = 1;
  var fitness = 0.0000001; //start out positive to avoid divide-by-0
  var <age = 0;
  var <reportingListenerPatch, <reportingListenerInstr, <listener;
  *new {|genosynth, voxInstr, voxDefaults, chromosomeMap, triggers, listenInstrName, evalPeriod=1, listenExtraArgs, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, voxInstr, voxDefaults, chromosomeMap, triggers).init(chromosome, listenInstrName, evalPeriod, listenExtraArgs);
  }
  init {|chromosome, listenInstrName_, evalPeriod_, listenExtraArgs_|
    listenInstrName = (listenInstrName_ ? Genosynth.defaultListenInstr);
    listenInstrName.asInstr.isNil.if({Error("no listenInstr" + listenInstrName_ + Genosynth.defaultListenInstr ++ ". Arse." ).throw;});
    evalPeriod = evalPeriod_ ? 1.0;
    listenExtraArgs = listenExtraArgs_ ? [];
    super.init(chromosome);
  }
  fitness {
    ^fitness.max(0.0000001);
  }
  fitness_ {|newFitness|
    fitness = newFitness;
  }
  age_ {|newAge|
    age = newAge;
  }
  createPatch {
    super.createPatch;
    reportingListenerInstr = ReportingListenerFactory.make(
      listenInstrName, listenExtraArgs,
      {
        |time, value|
        //write this using accessor notation to invite overrides.
        this.fitness_(value);
        this.age_(this.age + 1);
        //this.dump;
        //["updating correlation", this.hash, time, value, age].postln;
      }
    );
    reportingListenerPatch = Patch(
      reportingListenerInstr, [
        voxPatch,
        evalPeriod
      ]
    );
  }
  play {
    /*play reportingListener and voxPatch.*/
    //super.play;
    reportingListenerPatch.play(
      group: genosynth.voxGroup);
    this.trigger;
  }
  free {
    super.free;
    reportingListenerPatch.free;
  }
}


ReportingListenerFactory {
  /*Instrs like having names, so we make some on demand to keep things clean.
  TODO: I'm not totally sure if this is neccessary, and should check that
  after the current deadline crunch.*/
  classvar <counter = 0;
  *make {|listenInstrName, listenExtraArgs, onTrigFn, evalPeriod=1|
    /*takes a function of the form {|time, value| foo} */
    var newInstr;
    newInstr = Instr(
      "phenosynth.reportingListener.volatile." ++ counter.asString,
      {|in, evalPeriod=1|
        var totalFitness;
        totalFitness = A2K.kr(Mix.ar(Instr.ar(listenInstrName,
          [
            in,
            evalPeriod
          ] ++ listenExtraArgs//where we inject other busses etc
        ).poll(0.01, \a2k)).poll(0.01, \mix)).poll(0.01, \inner);
        //what's with those poll things? they make some explosions in the
        // fitness output code go away. if you can produce a reduced test
        // case for me, I am in your debt.
        LFPulse.kr((evalPeriod.reciprocal)/2).onTrig(
          onTrigFn, 
          //this sometimes explodes
          //totalFitness
          //the checkbadvalue doesn't stop all explosions, but won't hurt
          Select.kr(
            BinaryOpUGen(
              '>',
              CheckBadValues.kr(totalFitness),
              0
            ),
            [totalFitness, 0.0]
          ).poll(0.01, \sanitised)
        );
        //return inputs. We are analysis only.
        in;
      },
      [\audio], \audio
    );
    counter = counter+1;
    ^newInstr;
  }
}

PhenosynthBiome {
  //system setup
  var <genosynth; //Factory for new offspring
  var <tickPeriod; //how often we check
  var <>maxPopulation; //any more than this might explode something
  var <>numParents; //number of parents involved in birth
  var <>deathRate; //average death rate in population
  var <>birthRate; //average birth rate
  var <>deathFitness;
  var <>birthFitness;
  
  //state
  var <population, <numChannels, <clock, <ticker;
  *new {|genosynth, tickPeriod=1, maxPopulation=24, numParents=2, deathRate=0.05, birthRate=0.05, deathFitness=1, birthFitness=100,  initPopulation|
    ^super.newCopyArgs(
      genosynth, tickPeriod, maxPopulation, numParents, deathRate, birthRate, deathFitness, birthFitness
    ).init(
      initPopulation ? ((maxPopulation/2).ceil)
    );
  }
  ///
  //library of crossover operators for use in subclasses.
  //
  *uniformCrossover {|chromosomes|
    ^(chromosomes[0].size).collect({|i| chromosomes.slice(nil, i).choose;});
  }
  /*
  *pointCrossover {|chromosomes, points=2|
    //if you weren't fixated on *exactly* N points, this could be approximated
    //by a markov model with transition weights set to give the correct number
    //of crossings. So could, for that matter, uniformCrossover
  }
  *geneMachine {|states=2, stayProb=0.5|
    //placeholder for a simple zeroth order markov machine to manage crossovers
  }
  */
  //
  //library of mutation operators.
  //
  // Can a library have one book?
  *floatMutation{|chromosome, rate, amp=1.0|
    //in the absence of a rate, default to half the highest stable rate
    rate.isNil.if(rate=chromosome.size.reciprocal/2);
    chromosome.do({|val, index|
      (rate.coin).if ({
        chromosome[index] = (val + amp.sum3rand).wrap(0, 1);
      });
    });
    ^chromosome;
  }
  /*
  *bitwiseMutation{|chromosome, rate|
    //in the absence of a rate, default to the highest
    rate.isNil.if(rate=chromosome.size.reciprocal);
  }
  *bitwiseGrayCodeMutation{|chromosome, rate|
    //in the absence of a rate, default to the highest
    rate.isNil.if(rate=chromosome.size.reciprocal);
  }
  */
  *weightedSelectIndices {|weights, rate|
    // randomly choose indices from `weights`, weighted by their value, with a
    // mean probability of `rate`. Handy for selection processes.
    // Note that for high rates, this gets silly
    var meanWeight = weights.mean;
    ^weights.indicesSuchThat({|weight, i|
      (rate * weight / meanWeight).coin
    })
  }
  init {|initPopulation|
    population = List();
    initPopulation.do({this.spawn;});
  }
  play {
    clock = TempoClock.new(tickPeriod.reciprocal, 1);
    ticker = Task.new({loop {this.tick; 1.wait;}}, clock);
    ticker.start;
  }
  free {
    ticker ?? {ticker.stop;};
    clock ?? {clock.stop;};
    {population.size>0}.while({this.popIndividual});
  }
  spawn {|chromosome|
    var ind = genosynth.spawn(chromosome);
    ind.play;
    ^this.pushIndividual(ind);
  }
  pushIndividual {|ind|
    population.add(ind);
    ^ind;
  }
  popIndividualAt {|ind=0|
    this.popIndividual(population[ind]);
  }
  popIndividual {|ind|
    population.remove(ind);
    ind.free;
  }
  popIndividualsAt {|indList=#[]|
    indList.asArray.sort.reverse.do({|ind|
      this.popIndividual(ind);
    });
  }
  popIndividuals {|indList=#[]|
    indList.do({|ind|
      this.popIndividual(ind);
    });
  }
  time {
    ^clock.elapsedBeats.floor;
  }
  tick {
    this.cullPopulation;
    this.breedPopulation;
    this.immigrate;
  }
  fitnesses {
    //make sure this returns non-negative numbers, or badness ensues
    ^population.collect({|i| i.fitness;}).max(0);
    //alternative version, including aging, disabled while i sort this shizzle
    //^population.collect({|i| i.fitness/(2.pow(i.age/4));}).max(0);
  }
  ages {
    //make sure this returns non-negative numbers, or badness ensues
    ^population.collect({|i| i.age;});
  }
  immigrate {
    //hack version
    (this.population.size<3).if({this.spawn;});
  }
  findReapable {|rate|
    //^this.findReapableByDeathRate(rate);
    ^this.findReapableByRoulette(rate);
  }
  findSowable {|rate|
    ^this.findSowableByRoulette(rate);
  }
  findSowableByBirthRate {|rate|
    //find parents based on fitness. returns them.
    //possibly buggy.
    var posFitnesses;
    var hitList;
    rate.isNil.if({rate=birthRate});
    posFitnesses = this.fitnesses;
    hitList = this.class.weightedSelectIndices(posFitnesses, rate
      ).collect({|i| population[i];});
    ^hitList;
  }
  findReapableByDeathRate {|rate|
    //choose enough doomed to meet the death rate on average, weighted by
    // fitness
    //possibly buggy. seems to miss fitness laggards
    var negFitnesses;
    var posFitnesses;
    var hitList;
    rate.isNil.if({rate=deathRate});
    posFitnesses = this.fitnesses;
    //not strictly *negative* fitnesses, but inverted
    negFitnesses = posFitnesses.maxItem-posFitnesses;
    hitList = this.class.weightedSelectIndices(negFitnesses, rate
      ).collect({|i| population[i];}).select({|i| i.age>0;});
    ["hitList", hitList.collect({|i| i.fitness;})].postln;
    ^hitList;
  }
  findReapableByRoulette {|rate|
    //choose enough doomed to meet the death rate on average, by fitness-
    // weighted roulette
    var hitList, localFitnesses, negFitnesses, meanFitness;
    rate.isNil.if({rate=deathRate});
    localFitnesses = population.select({|i| i.age>0}).collect({|i| i.fitness;});
    //this array operation business fails for empty lists...
    localFitnesses.isEmpty.if({^[]});
    negFitnesses = localFitnesses.reciprocal;
    meanFitness = negFitnesses.mean;
    //["inverting", meanFitness].postln;
    //localFitnesses.postln;
    //negFitnesses.postln;
    hitList = population.select(
      {|i| (i.age>0) && ((((i.fitness.reciprocal)/meanFitness)*rate).coin)});
    //["hitList", hitList.collect({|i| i.fitness;})].postln;
    ^hitList;
  }
  findSowableByRoulette {|rate|
    //choose enough proud parents to meet the birth rate on average, by
    // fitness-weighted roulette
    var hitList, localFitnesses, meanFitness;
    rate.isNil.if({rate=birthRate});
    localFitnesses = population.select({|i| i.age>0}).collect({|i| i.fitness;});
    //this array operation business fails for empty lists...
    localFitnesses.isEmpty.if({^[]});
    meanFitness = localFitnesses.mean;
    //["inverting", meanFitness].postln;
    //localFitnesses.postln;
    hitList = population.select(
      {|i| (i.age>0) && ((((i.fitness)/meanFitness)*rate).coin)});
    //["hitList", hitList.collect({|i| i.fitness;})].postln;
    ^hitList;
  }
/*  chooseBirthNumber{|rate|
    //find number of births to have
    rate.isNil.if({rate=birthRate});
    //Modeled using Binomial distributin.
    //could be Poisson.
    ^population.size.collect(rate.coin.binaryValue).sum;
  }*/
  cullPopulation {
    var doomed = this.findReapable(deathRate);
    // ["mean fitness", this.fitnesses.mean].postln;
    doomed.isEmpty.not.if({(["killing"] ++ doomed ++ ["with fitnesses"] ++ doomed.collect({|ind| ind.fitness;})).postln;});
    this.popIndividuals(doomed);
    ["mean fitness", this.fitnesses.mean].postln;
  }
  breedPopulation {
    var allParents, numChildren;
    allParents = this.findSowable(birthRate);
    //this number is also how many kids they'll have, for the lack of a better
    // idea. But we respect maxPopulation.
    numChildren = [(maxPopulation-population.size), allParents.size].minItem;
    //for simplicity, we do not prevent birth by onanism here, nor by
    // threesomes etc.
    //let the shagging commence.
    numChildren.do({
      var parentChromosomes, childChromosome;
      parentChromosomes = numParents.collect({
        allParents.choose.chromosome;
      });
      childChromosome = this.crossover(parentChromosomes);
      childChromosome = this.mutate(childChromosome);
      this.spawn(childChromosome);
    });
  }
  crossover {|chromosomes|
    ^this.class.uniformCrossover(chromosomes.asArray);
  }
  mutate {|chromosome|
    ^this.class.floatMutation(chromosome.asArray);
  }
}

PhenosynthBiomeFitnessPlot {
  var <biome, <plotter, <clock, <tickTime;
  *new {|biome, name="biome_fitness", bounds, parent|
    ^super.newCopyArgs(biome).init(name, bounds, parent);
  }
  init {|name, bounds, parent|
    plotter = Plotter.new(name, bounds, parent);
    plotter.plotMode = \steps;
    tickTime = [(biome.tickPeriod/2), 1.0].maxItem;
    AppClock.play(Routine({{
      //["updating", biome.fitnesses, plotter.data ].postln;
      plotter.value_([biome.fitnesses, biome.ages]);
      plotter.refresh;
      tickTime.yield;
    }.loop}));
  }
}