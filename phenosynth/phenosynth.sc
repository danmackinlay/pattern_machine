/*
Phenosynth: Classes for phenotypic selection of Instrs

NOTES:

* Note that Instr loading is buggy - see http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Instr-calling-Crashes-SC-td4165267.html

  * you might want to use HJH's Instr.loadAll; workaround.
  
TODO:


* Urgent

  * have a singleton handling server sync to avoid ordering problems
  * rewrite the fitness stuff using bus .get business instead of OSCResponderNode.
  * convert judges to control rate, mono.
  * set up server options maxSynthDefs for easier synth management, or clear synthdefs. (see http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/too-many-Synthdefs-td5116364.html) 
  * LFOs
  * give fitness more accumulatey flavour using Integrator
  * give lifespans using the exponential distribution \lambda \e ^-\lambda \e
  * TODO: scale birthRate and deathRate so that they fit eventual fitness
  * reseed population when they all die
  * better aging calculations
  * sort out the interactions of all these different tick rates and periods.
  * work out why negFitness it can explode when population gets to 2 or less.
    (synthdef explosion?)
  * space out births, since that seems to stop exploding fitnesses.

* Handle "free controls", values that are passed in live by the user. (esp for
  triggers)
  
  * alter chromosome if Specs are changed through UI or any other means, using
    all that Dependent business

* Give the faintest of indications that I do care about tests
* work out a better way to handle non-chromosome'd arguments. Right now I
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
* consistently use either class or instance methods for selection/mutation
  operators

CREDITS:
Thanks to Martin Marier and Crucial Felix for tips that make this go, and
James Nichols for the peer pressure to do it.
*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr. You would have one of
  these for each population, as a rule.*/
  var <voxInstr, <voxDefaults, <judgeInstrName, <judgeExtraArgs, <sourceGroup, <outBus, <numChannels, <>phenoClass, <chromosomeMap, <triggers, <judgeInstr, <evalPeriod, <voxGroup, <all, <responder;
  classvar <defaultVoxInstr="phenosynth.vox.default";
  classvar <defaultJudgeInstr="phenosynth.judges.default";

  *new { |voxName, voxDefaults, judgeInstrName, judgeExtraArgs, sourceGroup, outBus, numChannels, phenoClass|
    //voxName - name, or Instr, that will be source
    //voxDefault - array of default args to voxName
    //judgeInstrName, judgeExtraArgs - like voxName, but for judgeing Instr
    //sourceGroup - a group that we must come after (Should we jsut supply the group to be in?)
    ^super.newCopyArgs(
      (voxName ? Genosynth.defaultVoxInstr).asInstr,
      (voxDefaults ? []),
      (judgeInstrName ? Genosynth.defaultJudgeInstr),
      (judgeExtraArgs ? []),
      sourceGroup,
      (outBus ? 0),
      (numChannels ? 1),
      (phenoClass ? ListenPhenosynth)).init;
  }
  init {
    all = IdentityDictionary.new;
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
    responder = OSCresponderNode(
      voxGroup.server.addr,
      { |t, r, msg| ['t,r,msg',t,r,msg].postln; }
    ).add;
  }
  free {
    //I think I shouldn't free the phenosynths here, just the OSC stuff.
    //playing is handled by the Biome.
    //all.do({|item,i| item.free; });
    voxGroup.free;
    //maybe the whole responder infrastructure shoudl be moved into the biome    
    //in fact, so there is not this dual responsibility for their resources?
    responder.remove;
  }
  spawnNaked { |chromosome|
    //just return the phenosynth itself, without listeners
    ^Phenosynth.new(this, voxInstr, voxDefaults, chromosomeMap, triggers, chromosome);
  }
  spawn { |chromosome|
    //return a listened phenosynth
    var newPhenosynth;
    newPhenosynth = phenoClass.new(this, voxInstr, voxDefaults, chromosomeMap, triggers, judgeInstrName, evalPeriod, judgeExtraArgs, chromosome);
    //Should this registering-with-all business be the job of the Phenosynth
    //for consistency?
    all.put(newPhenosynth.identityHash, newPhenosynth);
    ^newPhenosynth;
  }
  reap { |phenosynth|
    all.removeAt(phenosynth.identityHash);
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
    genosynth.reap(this);
    voxPatch.free;
  }
}

ListenPhenosynth : Phenosynth {
  var <judgeInstrName;
  var <judgeExtraArgs;
  var <evalPeriod = 1;
  var fitness = 0.0000001; //start out positive to avoid divide-by-0
  var <age = 0;
  var <reportPatch, <judgePatch, <listenPatch;
  *new {|genosynth, voxInstr, voxDefaults, chromosomeMap, triggers, judgeInstrName, evalPeriod=1, judgeExtraArgs, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, voxInstr, voxDefaults, chromosomeMap, triggers).init(chromosome, judgeInstrName, evalPeriod, judgeExtraArgs);
  }
  init {|chromosome, judgeInstrName_, evalPeriod_, judgeExtraArgs_|
    judgeInstrName = (judgeInstrName_ ? Genosynth.defaultJudgeInstr);
    judgeInstrName.asInstr.isNil.if({Error("no judgeInstr" + judgeInstrName_ + Genosynth.defaultJudgeInstr ++ ". Arse." ).throw;});
    evalPeriod = evalPeriod_ ? 1.0;
    judgeExtraArgs = judgeExtraArgs_ ? [];
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
    var judgeInstr;
    var reportInstr;
    var listenInstr;
    super.createPatch;
    //do i really need these Instrs as instance vars? don't think so
    judgeInstr = Instr(judgeInstrName);
    reportInstr = Instr("phenosynth.reporter");
    listenInstr = Instr("phenosynth.thru");
    ["judge, report, listen", judgeInstr, reportInstr, listenInstr].postln;
    judgePatch = Patch(
      judgeInstr, [
        voxPatch,
        evalPeriod
      ] ++ judgeExtraArgs
    );
    reportPatch = Patch(
      reportInstr, [
        judgePatch,
        evalPeriod,
        this.identityHash
      ]
    );
/*    listenPatch = Patch(
      listenInstr, [
        voxPatch
      ]
    );
*/  }
  play {
    /*play reportingListener and voxPatch.*/
    //super.play;
    //listenPatch.play(
    //  group: genosynth.voxGroup);
    reportPatch.play(
      group: genosynth.voxGroup);
    this.trigger;
  }
  free {
    ["freeing listener"].postln;
    super.free;
    judgePatch.free;
    reportPatch.free;
    //listenPatch.free;
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
  var <>mutationRate;
  var <>mutationAmp;
  //state
  var <population, <numChannels, <clock, <ticker;
  *new {|genosynth, tickPeriod=1, maxPopulation=24, numParents=2, deathRate=0.05, birthRate=0.05, deathFitness=1, birthFitness=100, mutationRate, mutationAmp=0.3, initPopulation|
    ^super.newCopyArgs(
      genosynth, tickPeriod, maxPopulation, numParents, deathRate, birthRate, deathFitness, birthFitness, (mutationRate ?? {genosynth.chromosomeMap.size.reciprocal/2;}), mutationAmp
    ).init(
      initPopulation ? (maxPopulation)
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
  floatMutation{|chromosome, rate, amp|
    //in the absence of a rate, default to half the highest stable rate
    rate.isNil.if({rate=mutationRate});
    amp.isNil.if({amp=mutationAmp});
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
  init {|initPopulation|
    population = List();
    { 
      initPopulation.do({ |i| 
        {
          ((1.0.rand)+0.5)}.value.wait;
        ["Threadin...", i, this.spawn].postln;
      })
    }.fork;
    //initPopulation.do({this.spawn;});
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
    ^this.findReapableByRoulette(rate);
  }
  findSowable {|rate|
    ^this.findSowableByRoulette(rate);
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
    ^this.floatMutation(chromosome.asArray);
  }
  police {|chromosome|
    //I get two types of occasional horrible errors. This is a nasty, nasty hack to kill them
    
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