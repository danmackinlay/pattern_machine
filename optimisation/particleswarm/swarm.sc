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

	//this really should be private coz of GUIs and the like
	var <params;

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
	var <swarmLagFitnessRate=0;
	var <swarmLagDispersal=0;
	
	//flag to stop iterator gracefuly.
	var playing = false;
	
	var <>swarmName = "swarm";
	var netSender = nil;
	var <netAddr = nil;
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
			\clockRate: 5.0,
			\selfTracking: 2.0,
			\groupTracking: 2.0,
			\momentum: 1.03,
			\memoryDecay: 0.99,
			\noise: 0.0001,
			\maxVel: 1.0,
			\individualConstructor: PSSynthDefPhenotype,
			\populationSize: 30,
			\shortLagCoef: 0.1,
			\longLagCoef: 0.01,
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
		swarmLagMeanPosition =  [1,1] *.t (0.5.dup(params.initialChromosomeSize));
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
	prPopulate {
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
		controller.prConnect(this);
		controller.fitnessPollRate = rate;
		this.prPopulate;
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
			//we are going to track one aprticular individual
			(phenotype==exemplar).if({maybeLog = logExemplar;});

			vecLen = phenotype.chromosome.size;
			
			// first, scale down past fitnesses by a decay factor
			bestKnownFitnessTable.keysValuesDo({|key, val|
				bestKnownFitnessTable[key] = val*(params.memoryDecay);
			});
			//now, ask myself for my best fitnesses, and compare to mine
			myCurrentPos = phenotype.chromosome;
			myCurrentFitness = cookedFitnessMap[phenotype];
			myBestPos = bestKnownPosTable[phenotype] ? myCurrentPos;
			myBestFitness = bestKnownFitnessTable[phenotype] ? myCurrentFitness;
			myDelta = (myBestPos - myCurrentPos);
			
			// now, ask my neighbours
			myNeighbourhood = this.getNeighbours(phenotype);
			myBestNeighbour = myNeighbourhood[
				myNeighbourhood.maxIndex({|neighbour|
					bestKnownFitnessTable[neighbour]
				});
			];
			myNeighbourhoodBestPos = bestKnownPosTable[myBestNeighbour];
			myNeighbourhoodBestFitness = bestKnownFitnessTable[myBestNeighbour];
			myNeighbourhoodDelta = (myNeighbourhoodBestPos - myCurrentPos);
			
			//get my velocity, coz we're going to update it
			myVel = velocityTable[phenotype];
			
			maybeLog.([\pos] ++ myCurrentPos);
			maybeLog.([\fitness, myCurrentFitness]);
			maybeLog.([\mybestpos] ++ myBestPos);
			maybeLog.([\mybest, myBestFitness]);
			maybeLog.([\mydelta] ++ myDelta);
			maybeLog.([\groupbest, myNeighbourhoodBestFitness]);
			maybeLog.([\groupbestpos] ++ myNeighbourhoodBestPos);
			maybeLog.([\groupdelta] ++ myNeighbourhoodDelta);
			maybeLog.([\vel1] ++ myVel);
			
			//update
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
			phenotype.chromosome = myNextPos;
			controller.updateIndividual(phenotype);
			
			//Now, update fitness tables to reflect how good that last position was
			(myCurrentFitness>myBestFitness).if({
				myBestFitness = myCurrentFitness;
				myBestPos = myCurrentPos;
			});
			bestKnownPosTable[phenotype] = myBestPos;
			bestKnownFitnessTable[phenotype] = myBestFitness;			
		});
		this.updateStatistics;
		netSender.value;
		iterations = iterations + 1;
	}
	setParam {|statekey, stateval|
		params[statekey] = stateval;
		params.changed(statekey, stateval);
	}
	updateStatistics{
		var lastMeanFitness;
		var meanChromosome;
		var lagCoefs; 
		var convLagCoefs;
		
		//vector of lag coefficients:
		lagCoefs = [params[\shortLagCoef], params[\longLagCoef]];
		convLagCoefs = 1.0 - lagCoefs;
		
		//some state that needs extra work to track
		lastMeanFitness = swarmMeanFitness;
		swarmMeanFitness = this.meanFitness;
        meanChromosome = this.meanChromosome;
		
		//calculate lags
		swarmLagPosSpeed = (lagCoefs * this.meanVelocity.squared.mean.sqrt) + (convLagCoefs * swarmLagPosSpeed);
		swarmLagMeanPosition = (lagCoefs *.t meanChromosome) + (swarmLagMeanPosition * convLagCoefs );
		swarmLagMeanFitness = (lagCoefs * this.meanFitness) + (convLagCoefs * swarmLagMeanFitness);
		swarmLagFitnessRate = (lagCoefs * (swarmMeanFitness-lastMeanFitness)) + (convLagCoefs * swarmLagFitnessRate);
		swarmLagDispersal = (lagCoefs * this.meanDistance(meanChromosome)) + (convLagCoefs * swarmLagDispersal);
		// careful, operator order and depth get weird with this last one:
		/*params.log.log(msgchunks:[\subtick1, \meanc] ++ meanChromosome ++
			[\lagmeanc] ++ swarmLagMeanPosition ++
			[\dimsina, meanChromosome.size, meanChromosome[0].size] ++
			[\dimsinb, swarmLagMeanPosition.size, swarmLagMeanPosition[0].size],
			tag:\stats, priority: 1);*/
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
	net_ {|addr|
		netAddr = addr;
		netAddr.isNil.if({
			netSender = nil;
		}, {
			netSender = {
				var path = "/swarm/%".format(swarmName);
				var i = 0;
				cookedFitnessMap.keysValuesDo({|agent,fitness|
					netAddr.sendMsg(path, i, fitness, *(agent.chromosome));
					i = i+1;
				});
			};
		});
		
	}
	randomize {|...targets|
		(targets.size == 0).if({targets = population});
		targets.postln;
		targets.do({|phenotype|
			phenotype.chromosome = {1.0.rand}.dup(phenotype.chromosome.size);
			controller.updateIndividual(phenotype);
		});
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
	prPopulate {
		super.prPopulate;
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
				plotter.scatter(locs);
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
	var <swarm, <>pollRate;
	var <>maxFitness;
	var <paramsModel;
	var <paramsGuiUpdater;
	var <window, <widgets;
	var worker;
	
	*new{|swarm, pollRate=5, maxFitness=1| ^super.newCopyArgs(swarm, pollRate, maxFitness).initSwarmGui;}
	
	initSwarmGui {
		var ezSliderWidth, meterWidth, labelWidth, numberWidth, statsHeight;
		widgets = ();
		//model
		paramsModel = swarm.params;
		//view
		window = FlowView(bounds:500@600, windowTitle: "window!").front;
		CmdPeriod.doOnce({window.close;});
		ezSliderWidth = window.bounds.width - 6;
		labelWidth = 80;
		meterWidth = ezSliderWidth - labelWidth - 8;
		numberWidth = 60;
		statsHeight = 30;
		
		widgets.clockRate = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "clockrate",
			controlSpec: ControlSpec.new(1, 100,
				\exponential,
				default: paramsModel.clockRate,
				units:\hz),
			initVal: paramsModel.clockRate,
			action: {|view| this.setParam(\clockRate, view.value);}
		);
		widgets.clockRate.numberView.maxDecimals=4;
		widgets.stepSize = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "stepsize",
			controlSpec: ControlSpec.new(0.0001, 1,
				\exponential,
				default: paramsModel.stepSize,
			),
			initVal: paramsModel.stepSize,
			action: {|view| this.setParam(\stepSize, view.value);}
		);
		widgets.stepSize.numberView.maxDecimals=4;
		widgets.selfTracking = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "selfTrack",
			controlSpec: ControlSpec.new(0.0, 2.0,
				\linear,
				default: paramsModel.selfTracking,
			),
			initVal: paramsModel.selfTracking,
			action: {|view| this.setParam(\selfTracking, view.value);}
		);
		widgets.selfTracking.numberView.maxDecimals=4;
		widgets.groupTracking = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "groupTrack",
			controlSpec: ControlSpec.new(0.0, 2.0,
				\linear,
				default: paramsModel.groupTracking,
			),
			initVal: paramsModel.groupTracking,
			action: {|view| this.setParam(\groupTracking, view.value);}
		);
		widgets.groupTracking.numberView.maxDecimals=4;
		widgets.momentum = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "momentum",
			controlSpec: ControlSpec.new(0.9, 0.9.reciprocal,
				\exponential,
				default: paramsModel.momentum,
			),
			initVal: paramsModel.momentum,
			action: {|view| this.setParam(\momentum, view.value);}
		);
		widgets.momentum.numberView.maxDecimals=4;
		widgets.noise = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "noise",
			controlSpec: ControlSpec.new(0.0001, 1,
				\exponential,
				default: paramsModel.noise,
			),
			initVal: paramsModel.noise,
			action: {|view| this.setParam(\noise, view.value);}
		);
		widgets.noise.numberView.maxDecimals=4;
		widgets.memoryDecay = EZSlider.new(
			parent: window,
			numberWidth: numberWidth,
			labelWidth: labelWidth,
			bounds: Point(ezSliderWidth, 16),
			label: "memory",
			controlSpec: ControlSpec.new(0.9, 1.0,
				\exponential,
				default: paramsModel.memoryDecay,
			),
			initVal: paramsModel.memoryDecay,
			action: {|view| this.setParam(\memoryDecay, view.value);}
		);
		widgets.memoryDecay.numberView.maxDecimals=4;
		
		widgets.meanPos = MultiSliderView(window, Rect(0,0,ezSliderWidth,100));
		widgets.meanPos.size = swarm.params[\initialChromosomeSize] ? 7;
		widgets.meanPos.elasticMode = 1;
		widgets.meanPos.editable = false;
		widgets.meanPos.indexThumbSize = ezSliderWidth/(widgets.meanPos.size);
		widgets.meanPos.valueThumbSize = 2;
		widgets.meanPos.value = swarm.meanChromosome;
		
		window.startRow;
		
		StaticText.new(window, Rect(0, 0, labelWidth, statsHeight)).string="fitness";
		widgets.fitness = MultiSliderView(window, Rect(0, 0, meterWidth, statsHeight));
		widgets.fitness.size = 2;
		widgets.fitness.elasticMode = 1;
		widgets.fitness.editable = false;
		widgets.fitness.indexThumbSize = 20;
		widgets.fitness.valueThumbSize = 2;
		widgets.fitness.indexIsHorizontal = false;
		widgets.fitness.isFilled = true;
		widgets.fitness.value = swarm.swarmLagMeanFitness? [0,0];
		widgets.fitness.reference = [0,0].linlin(0.0, maxFitness, 0.0, 1.0);
		
		window.startRow;
		
		StaticText.new(window, Rect(0, 0, labelWidth, statsHeight)).string="fitnessrate";
		widgets.fitnessRate = MultiSliderView(window, Rect(0, 0, meterWidth, statsHeight));
		widgets.fitnessRate.size = 2;
		widgets.fitnessRate.elasticMode = 1;
		widgets.fitnessRate.editable = false;
		widgets.fitnessRate.indexThumbSize = 20;
		widgets.fitnessRate.valueThumbSize = 2;
		widgets.fitnessRate.indexIsHorizontal = false;
		widgets.fitnessRate.isFilled = true;
		widgets.fitnessRate.value = swarm.swarmLagFitnessRate? [0,0];
		widgets.fitnessRate.reference = [0,0].linlin(
			-1 * (paramsModel[\stepSize] * maxFitness),
			(paramsModel[\stepSize] * maxFitness),
			0.0, 1.0
		);
		
		window.startRow;
		
		StaticText.new(window, Rect(0, 0, labelWidth, statsHeight)).string="dispersal";
		widgets.dispersal = MultiSliderView(window, Rect(0, 0, meterWidth, statsHeight));
		widgets.dispersal.size = 2;
		widgets.dispersal.elasticMode = 1;
		widgets.dispersal.editable = false;
		widgets.dispersal.indexThumbSize = 20;
		widgets.dispersal.valueThumbSize = 2;
		widgets.dispersal.indexIsHorizontal = false;
		widgets.dispersal.isFilled = true;
		widgets.dispersal.value = swarm.swarmLagDispersal? [0,0];
		widgets.dispersal.reference = [0,0].linlin(0.0, 0.3, 0.0, 1.0);
		
		window.startRow;
		
		StaticText.new(window, Rect(0, 0, labelWidth, statsHeight)).string="speed";
		widgets.posSpeed = MultiSliderView(window, Rect(0, 0, meterWidth, statsHeight));
		widgets.posSpeed.size = 2;
		widgets.posSpeed.elasticMode = 1;
		widgets.posSpeed.editable = false;
		widgets.posSpeed.indexThumbSize = 20;
		widgets.posSpeed.valueThumbSize = 2;
		widgets.posSpeed.indexIsHorizontal = false;
		widgets.posSpeed.isFilled = true;
		widgets.posSpeed.value = swarm.swarmLagPosSpeed? [0,0];
		widgets.posSpeed.reference = [0,0];
				
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
		worker = AppClock.play(Routine({|appClockTime|
			loop({
				this.updateStatistics;
				pollRate.reciprocal.yield;
			})
		}));
	}
	//controller. This is the only supported accessor for swarm params.
	setParam {|statekey, stateval|
		swarm.setParam(statekey, stateval);
	}
	updateStatistics {
		widgets.meanPos.value = swarm.meanChromosome;
		widgets.fitness.value = swarm.swarmLagMeanFitness.linlin(0.0, maxFitness, 0.0, 1.0);
		widgets.fitnessRate.value = swarm.swarmLagFitnessRate.linlin(
			-1 * (paramsModel[\stepSize] * maxFitness),
			(paramsModel[\stepSize] * maxFitness),
			0.0, 1.0
		);
		widgets.dispersal.value = swarm.swarmLagDispersal.linlin(0, 0.3, 0.0, 1.0);
		widgets.posSpeed.value = swarm.swarmLagPosSpeed;
	}
}
