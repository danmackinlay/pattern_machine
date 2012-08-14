PSOptimisingSwarm {
	/* handle a swarm of agents optimising.
	This is a little like PSControllerIsland, but not enough that it is worth it
	to subclass.
	There should be some duck-typing possible, though.
	
	Also note that unlike the class hierarchy of the GA-type selection, I 
	make no allowance for non-synth-based selection.
	This is because of Deadlines.
	*/
	
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, zero_peak];
	classvar <defaultInitialChromosomeFactory = #[phenosynth, chromosome_fact, basic];
	classvar <defaultIndividualFactory = #[phenosynth, individual_fact, defer_to_constructor];
	classvar <defaultScoreEvaluator = #[phenosynth, score_evals, chromosomemean];
	classvar <defaultScoreCooker = #[phenosynth, score_cookers, raw];
	classvar <defaultTerminationCondition = #[phenosynth, termination_conds, never];

	var <>params;

	var <>controller;
	var <>particles;
	var <worker;

	//These are the main state variables
	var <population;
	var <rawScoreMap;
	var <cookedFitnessMap;
	var <iterations = 0;
	var <velocityTable;
	var <bestKnownPosTable;
	var <bestKnownFitnessTable;
	
	//tracking convergence
	var <swarmLagMeanPosition;
	var <swarmLagPosSpeed=0;
	var <swarmMeanFitness=0;
	var <swarmLagMeanFitness=0;
	var <swarmLagFitnessSpeed=0;
	var <swarmLagDispersal=0;
	
	//flag to stop iterator gracefuly.
	var playing = false;

	/*
	Here are the variables that hold the operator functions.
	Paths are coerced to functions at instantiation time to avoid problems with
	not knowing when the Library gets filled.
	*/
	var <initialChromosomeFactory;
	var <individualFactory;
	var <scoreEvaluator;
	var <scoreCooker;
	var <terminationCondition;
	
	//we log debug information about one particular particle
	var <>exemplar;

	// default values for that parameter thing
	*defaultParams {
		^(
			\initialChromosomeSize: 4,
			\stepSize: 0.01,
			\clockRate: 10.0,
			\selfTracking: 2.0,
			\groupTracking: 2.0,
			\momentum: 1.03,
			\memoryDecay: 0.99,
			\noise: 0.0001,
			\maxVel: 1.0,
			\individualConstructor: PSSynthDefPhenotype,
			\populationSize: 30,
			\lagCoef: 0.1,
			\log: NullLogger.new,
		);
	}
	*new {|params|
		var thisNew = super.newCopyArgs(
			this.defaultParams.updatedFrom(params ? Event.new)
		).init;
		^thisNew;
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
		population = IdentitySet.new(100);
		rawScoreMap = IdentityDictionary.new(100);
		cookedFitnessMap = IdentityDictionary.new(100);
		velocityTable = IdentityDictionary.new(100);
		bestKnownPosTable = IdentityDictionary.new(100);
		bestKnownFitnessTable = IdentityDictionary.new(100);
		swarmLagMeanPosition = 0.5.dup(params.initialChromosomeSize);
		this.initOperators;
	}
	initOperators {
		this.initialChromosomeFactory = this.class.defaultInitialChromosomeFactory;
		this.individualFactory = this.class.defaultIndividualFactory;
		this.scoreEvaluator = this.class.defaultScoreEvaluator;
		this.scoreCooker = this.class.defaultScoreCooker;
		this.terminationCondition = this.class.defaultTerminationCondition;
	}
	add {|phenotype|
		var res, velocity;
		res = controller.playIndividual(phenotype);
		res.isNil.if({
			//no busses available to play on
			params.log.log(msgchunks: ["Could not add phenotype", phenotype], tag: \resource_exhausted);
			^nil;
		}, {
			population.add(phenotype);
			velocityTable[phenotype] = {1.0.rand2}.dup(params.initialChromosomeSize);
			bestKnownPosTable[phenotype] = phenotype.chromosome;
			bestKnownFitnessTable[phenotype] = 0.0;
			^phenotype;
		});
	}
	remove {|phenotype|
		population.remove(phenotype);
		rawScoreMap.removeAt(phenotype);
		cookedFitnessMap.removeAt(phenotype);
		velocityTable.removeAt(phenotype);
		bestKnownPosTable.removeAt(phenotype);
		bestKnownFitnessTable.removeAt(phenotype);
		controller.freeIndividual(phenotype);
		(exemplar == phenotype).if({exemplar = population.choose;});
	}
	populate {
		params.populationSize.do({
			var noob, chromosome;
			chromosome = initialChromosomeFactory.value(params);
			noob = individualFactory.value(params, chromosome);
			this.add(noob);
		});
		exemplar = population.choose;
	}
	setFitness {|phenotype, value|
		rawScoreMap[phenotype] = value;
	}	
	play {|controller|
		var clock, rate;
		//pass the controller a reference to me so it can push notifications
		this.controller = controller;
		rate = params.clockRate ?? {controller.fitnessPollRate ? 1;};
		controller.connect(this);
		controller.fitnessPollRate = rate;
		this.populate;
		clock = TempoClock.new(rate, 1);
		params.clockRate = rate;
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
	getNeighbours {|phenotype|
		^population.asArray;
	}
	tend {
		/* Note there is a potential problem with asynchronous updating:
		particles modify the bestness tables in situ
		
		Also fitness is noisy because of a) lags and b) asynchronous fitness polling.
		*/
		var logExemplar = {|...args|
			params.log.log(
				msgchunks: args,
				priority: 0,
				tag: \exemplar
			);
		};

		cookedFitnessMap = scoreCooker.value(params, rawScoreMap);
				
		cookedFitnessMap.keys.do({|phenotype|
			var myCurrentFitness, myBestFitness, myNeighbourhoodBestFitness;
			var myCurrentPos, myBestPos, myNeighbourhoodBestPos, myNextPos;
			var myBestNeighbour;
			var myVel, myNeighbourhood;
			var myDelta, myNeighbourhoodDelta;
			var vecLen;
			var maybeLog = nil;
			(phenotype==exemplar).if({maybeLog = logExemplar;});

			myNeighbourhood = this.getNeighbours(phenotype);

			myCurrentPos = phenotype.chromosome;
			vecLen = phenotype.chromosome.size;
			
			myCurrentFitness = cookedFitnessMap[phenotype];
			myBestPos = bestKnownPosTable[phenotype] ? myCurrentPos;
			myBestFitness = bestKnownFitnessTable[phenotype] ? myCurrentFitness;
			
			myDelta = (myBestPos - myCurrentPos);
			
			myBestNeighbour = myNeighbourhood[
				myNeighbourhood.maxIndex({|neighbour|
					bestKnownFitnessTable[neighbour]
				});
			];
			
			myNeighbourhoodBestPos = bestKnownPosTable[myBestNeighbour];
			myNeighbourhoodBestFitness = bestKnownFitnessTable[myBestNeighbour];
			
			myNeighbourhoodDelta = (myNeighbourhoodBestPos - myCurrentPos);
			
			myVel = velocityTable[phenotype];
			
			params.log.log(msgchunks: [\premove,
					\vel, myVel,
					\pos, myCurrentPos,
					\mydelta, myDelta,
				], priority: -1,
				tag: \moving);
			
			maybeLog.([\pos] ++ myCurrentPos);
			maybeLog.([\fitness, myCurrentFitness]);
			maybeLog.([\mybestpos] ++ myBestPos);
			maybeLog.([\mybest, myBestFitness]);
			maybeLog.([\mydelta] ++ myDelta);
			maybeLog.([\groupbest, myNeighbourhoodBestFitness]);
			maybeLog.([\groupbestpos] ++ myNeighbourhoodBestPos);
			maybeLog.([\groupdelta] ++ myNeighbourhoodDelta);
			maybeLog.([\vel1] ++ myVel);
			
			myVel = (params.momentum * myVel) +
				(params.selfTracking * ({1.0.rand}.dup(vecLen)) * myDelta) +
				(params.groupTracking * ({1.0.rand}.dup(vecLen)) * myNeighbourhoodDelta)+
				(params.noise * ({1.0.rand2}.dup(vecLen)));
			myVel = myVel.clip2(params.maxVel);
			maybeLog.([\vel2] ++ myVel);
			myNextPos = (myCurrentPos + (myVel * (params.stepSize))).clip(0.0, 1.0);
			//allow clipping of velocities to reflect hitting the edge:
			myVel = (myNextPos - myCurrentPos)/(params.stepSize);
			maybeLog.([\vel3] ++ myVel);
			velocityTable[phenotype] = myVel;
			maybeLog.([\newpos] ++ myNextPos);
			maybeLog.([\posdelta, (myNextPos - myCurrentPos)]);
			
			params.log.log(msgchunks: [\velupdate,
					\vel, myVel,
					\pos, myCurrentPos,
				], priority: -1,
				tag: \moving);
			
			phenotype.chromosome = myNextPos;
			controller.updateIndividual(phenotype);
			params.log.log(msgchunks: [\postmove,
					\phenotype, phenotype
				], priority: -1,
				tag: \moving);
			
			(myCurrentFitness>myBestFitness).if({
				myBestFitness = myCurrentFitness;
				myBestPos = myCurrentPos;
			});
			
			bestKnownPosTable[phenotype] = myBestPos;
			bestKnownFitnessTable[phenotype] = myBestFitness;
			
			bestKnownFitnessTable.keysValuesDo({|key, val|
				bestKnownFitnessTable[key] = val*(params.memoryDecay);
			});
		});
		this.trackConvergence;
		iterations = iterations + 1;
	}
	trackConvergence{
		var lastMeanFitness;
		var lagCoef = params.lagCoef;

		lastMeanFitness = swarmMeanFitness;
		swarmMeanFitness = this.meanFitness;
		
		swarmLagPosSpeed = (lagCoef * this.meanVelocity.squared.mean.sqrt) + ((1-lagCoef) * swarmLagPosSpeed);
		swarmLagMeanPosition = (lagCoef * this.meanChromosome.squared.mean.sqrt) + ((1-lagCoef) * swarmLagMeanPosition);
		swarmLagMeanFitness = (lagCoef * this.meanFitness) + ((1-lagCoef) * swarmLagMeanFitness);
		swarmLagFitnessSpeed = (lagCoef * (swarmMeanFitness-lastMeanFitness)) + ((1-lagCoef) * swarmLagFitnessSpeed);
		swarmLagDispersal = (lagCoef * this.meanDistance) + ((1-lagCoef) * swarmLagDispersal);
	}
	meanChromosome {
		//return a chromosome that is a mean of all current ones
		^population.collect(_.chromosome).asArray.mean;
	}
	meanFitness {
		// return the mean fitness for the whole population
		// (or 0 if there is no fitness yet)
		^(cookedFitnessMap.size>0).if({cookedFitnessMap.values.mean;}, 0);
	}
	meanDistance {|from|
		//return the mean square distance from a particular vector
		from = from ? this.meanChromosome;
		^population.collect(_.chromosome-from).asArray.squared.mean.mean.sqrt;
	}
	meanVelocity {
		^velocityTable.values.mean;
	}
	rankedPopulation {
		//return all population that have a fitness, ranked in descending order thereof.
		//Individuals that do not yet have a fitness are not returned
		^population.selectAs(
			{|i| cookedFitnessMap[i].notNil}, Array
		).sort({|a, b| cookedFitnessMap[a] > cookedFitnessMap[b] });
	}
	swarmMeanBestFitness {
		^bestKnownFitnessTable.values.asArray.mean;
	}
	free {
		super.free;
		controller.free;
	}
}

PSLocalOptimisingSwarm : PSOptimisingSwarm {
	var <neighbourTable;
	*defaultParams {
		var params = super.defaultParams;
		params.neighboursPerNode = 3;
		^params;
	}
	init {
		super.init;
		neighbourTable = IdentityDictionary.new(100);
	}
	populate {
		super.populate;
		this.createTopology;
	}
	getNeighbours {|phenotype|
		^neighbourTable[phenotype];
	}
	createTopology {
		//create a whole Renyi random social graph all at once
		// this is easier than bit-by-bit if we want to avoid preferential attachment dynamics
		// Maybe preferential attachment dynamics is desirable though? I dunno.
		var nLinks = [params.neighboursPerNode, params.populationSize-1].maxItem;
		population.do({|here|
			var unusedNeighbours = IdentitySet.newFrom(population); //this copies, right?
			unusedNeighbours.remove(here);
			nLinks.do({
				var there;
				there = unusedNeighbours.choose;
				unusedNeighbours.remove(there);
				this.addLink(here, there);
			});
		});
	}
	add {|phenotype|
		var added = super.add(phenotype);
		added.notNil.if({
			neighbourTable[phenotype] = Array.new;
		});
	}
	remove {|phenotype|
		super.remove(phenotype);
		neighbourTable.removeAt(phenotype);
	}
	addLink{|src, dest|
		neighbourTable[src] = neighbourTable[src].add(dest);
	}
}
SwarmGraph {
	var <swarm;
	var <worker;
	var <plotter;
	var <population;
	var <idhashes;
	
	*new {|swarm|
		^super.newCopyArgs(swarm).init;
	}
	init {
		//TODO: implement as "impulses" plot style
		population = swarm.population.asArray;
		idhashes = population.collect({|i|
			i.identityHash.asHexString;
		});
		plotter = GNUPlot.new;
		//fitness-relevant axis ranges.
		plotter.sendCmd("set xrange [0:1]");
		plotter.sendCmd("set yrange [0:1]");
		plotter.sendCmd("set zrange [0:]");
		worker = Routine.new({
			loop {
				//this plots a 2d slice of the chromosome, using the z axis for fitness
				// of said slice.
				var locs;
				locs = population.collect({|ind|
					//[\ind, ind].postln;
					[ind.chromosome[0..1] ++ swarm.cookedFitnessMap[ind]];
				});
				plotter.scatter(locs, idhashes);
				//state.locs = locs;
				(swarm.params.clockRate.reciprocal).yield;
			};
		}).play(AppClock);
	}
	stop {
		worker.stop;
		plotter.stop;
	}
}

SwarmGui {
	var <swarm, <window, <paramsGuiUpdater, <paramsModel, <paramsModelSetter;
	var <widgets;
	
	*new{|swarm| ^super.newCopyArgs(swarm).init;}
	
	init {
		widgets = ();
		//model
		paramsModel = swarm.params;
		//view
		window = FlowView(bounds:300@300, windowTitle: "window!").front;
		CmdPeriod.doOnce({window.close});
		
		widgets.clockRate = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "clockrate",
			controlSpec: ControlSpec.new(1, 100,
				\exponential,
				default: paramsModel.clockRate,
				units:\hz),
			initVal: paramsModel.clockRate,
			action: {|view| this.setParam(\clockRate, view.value);}
		);
		widgets.stepSize = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "stepsize",
			controlSpec: ControlSpec.new(0.0001, 1,
				\exponential,
				default: paramsModel.stepSize,
			),
			initVal: paramsModel.stepSize,
			action: {|view| this.setParam(\stepSize, view.value);}
		);
		widgets.selfTracking = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "selftracking",
			controlSpec: ControlSpec.new(0.0, 2.0,
				\linear,
				default: paramsModel.selfTracking,
			),
			initVal: paramsModel.selfTracking,
			action: {|view| this.setParam(\selfTracking, view.value);}
		);
		widgets.groupTracking = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "groupTracking",
			controlSpec: ControlSpec.new(0.0, 2.0,
				\linear,
				default: paramsModel.groupTracking,
			),
			initVal: paramsModel.groupTracking,
			action: {|view| this.setParam(\groupTracking, view.value);}
		);
		widgets.momentum = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "momentum",
			controlSpec: ControlSpec.new(0.9, 0.9.reciprocal,
				\exponential,
				default: paramsModel.momentum,
			),
			initVal: paramsModel.momentum,
			action: {|view| this.setParam(\momentum, view.value);}
		);
		widgets.noise = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "noise",
			controlSpec: ControlSpec.new(0.00001, 1,
				\exponential,
				default: paramsModel.noise,
			),
			initVal: paramsModel.noise,
			action: {|view| this.setParam(\noise, view.value);}
		);
		widgets.memoryDecay = EZSlider.new(
			parent: window,
			bounds: Point(window.bounds.width*0.9, 16),
			label: "memoryDecay",
			controlSpec: ControlSpec.new(0.9, 1.0,
				\exponential,
				default: paramsModel.memoryDecay,
			),
			initVal: paramsModel.memoryDecay,
			action: {|view| this.setParam(\memoryDecay, view.value);}
		);
		window.onClose_({
			paramsModel.removeDependant(paramsGuiUpdater);
		});
		paramsGuiUpdater = {|theChanger, what, val|
			{
				what.switch(
					\clockRate, { widgets.clockRate.value_(val);},
					\stepSize, { widgets.stepSize.value_(val);},
					\selfTracking, { widgets.selfTracking.value_(val);},
					\groupTracking, { widgets.groupTracking.value_(val);},
					\momentum, { widgets.momentum.value_(val);},
					\noise, { widgets.noise.value_(val);},
					\memoryDecay, { widgets.memoryDecay.value_(val);},
				);
			}.defer;
		};
		paramsModel.addDependant(paramsGuiUpdater);
	}
	//controller. This is the only supported accessor for swarm params.
	setParam {|statekey, stateval|
		paramsModel[statekey] = stateval;
		paramsModel.changed(statekey, stateval);
	}
}
