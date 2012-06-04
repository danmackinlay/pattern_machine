/*
(
//How the controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSSynthController.new(s, ~globalOuts);
~ind = PSSynthPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthPhenotype.newRandom)});
~control.all.do({|a,b,c| [a,b,c].postln;});
)
*/
PSSynthController {
	/*pass all server instructions through this guy to allow the instructions
	to be delivered in the right order and the boring bus/server allocation
	details to be abstracted away, and to track resources needing freeing.
	
	This basic controller only does *playing* of synths, presuming that you are
	going to rank them manually or something (e.g. Dan Stowell's neat GOAD.sc)
	
	A subclass, PSListenSynthController, handles setting up candidate
	phenosynths and listeners simultaneously.
	*/
	
	/*Instance vars are all public to aid debugging, but not much use to look 
	at unless you *are* debugging.*/
	var <numChannels;
	var <>outBus;
	var <server;
	var <all;
	var <playGroup;
	var <allocatedNodes;
	var <freedNodes;
	var <playing = false;
	var <island;
	var <log;
	
	*new {|numChannels=1, log|
		^super.newCopyArgs(numChannels).init(log);
	}
	init {|thisLog|
		allocatedNodes = IdentityDictionary.new;
		freedNodes = List.new;
		all = IdentityDictionary.new;
		log = thisLog ? NullLogger.new;
	}
	play {|serverOrGroup, outBus|
		serverOrGroup.isKindOf(Group).if(
			{
				server = serverOrGroup.server;
				playGroup = serverOrGroup;
			}, {
				server = serverOrGroup;
				playGroup = Group.head(server);
			}
		);
		this.outBus = outBus ?? { Bus.audio(server, numChannels)};
		//This sets a flag to allow playing of synths, so that we don't end
		//up with concurrency problems with playing/freeing
		playing = true;
		// also, we set an island to report back to about synth business
	}
	connect {|newIsland|
		//couple to an island
		island = newIsland;
	}
	playIndividual {|phenotype|
		var indDict;
		playing.not.if({"Controller is not playing!".throw});
		indDict = (\phenotype: phenotype);
		all.put(indDict.phenotype.identityHash, indDict);
		this.decorateIndividualDict(indDict);
		this.loadIndividualDict(
			indDict
		);
		this.actuallyPlayIndividual(indDict);
		{this.trackSynths(indDict);}.defer(0.5);
	}
	loadIndividualDict{|indDict|
		//pass
	}
	decorateIndividualDict {|indDict|
		indDict.playBus = outBus;
	}
	getSynthArgs {|indDict|
		var playArgs;
		playArgs = [\out, indDict.playBus, \gate, 1] ++ indDict.phenotype.chromosomeAsSynthArgs;
		^playArgs;
	}
	actuallyPlayIndividual {|indDict|
		//private
		indDict.playNode = Synth.new(
			indDict.phenotype.synthDef,
			this.getSynthArgs(indDict),
			target: playGroup
		);
		indDict.phenotype.clockOn;
	}
	trackSynths {|indDict|
		/*
		for debugging, associate each synth with a server node so I can see if
		anything is leaking.
		
		Note that this will, of course, eventually cause leaks of its own.
		*/
		indDict.values.do({|indDictEntry|
			indDictEntry.isKindOf(Synth).if({
				allocatedNodes[indDictEntry.nodeID] = indDictEntry.defName;
			});
		});
	}
	freeIndividual {|phenotype|
		var freed;
		freed = all.removeAt(phenotype.identityHash);
		freedNodes.add(freed);
		freed.notNil.if({
			// These should be separated, or the second eliminated by the first.
			freed.phenotype.stop(freed.playNode);//closes envelope
			freed.playNode.free;//forces synth to free
		});
		^freed;
	}
	free {
		/* Stop taking requests. */
		playing = false;
		
		/* Free synths
		   Do it in a routine to maximise our hope of killing ones spawned
		   concurrently. (you'd think no new ones would be spawned if we
		   didn't surrender control, no? Apparently this is not so.)*/
		Routine.new({
			while (
				{ (all.size > 0) },
				{ all.do(
					{|i|
						this.freeIndividual(i.phenotype);
						0.01.yield;
					});
				}
			)
		}).play;
	}
}

/*
(
//How the listening controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(s, ~globalOuts);
~ind = PSSynthPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthPhenotype.newRandom)});
~control.all.do({|a,b,c| [a,b,c].postln;});
)
*/
PSListenSynthController : PSSynthController {
	/*
	This Controller subclass sets up Synths and listeners to those synths
	simultaneously.
	*/
	var <>fitnessPollInterval;
	var <>listenGroup;
	var <>worker;
	var <>clock;
	var <>listenSynth;
	var <>leakCoef;
	var <busAllocator;
	var <maxPop;

	var <fitnessBusses;
	var <playBusses;
	var <jackNodes;
	
	//Toy example synth
	classvar <>defaultListenSynth = \ps_listen_eight_hundred;
	
	*new {|numChannels=1, log, fitnessPollInterval=1, listenSynth, leakCoef=0.5, maxPop=40|
		^super.new(numChannels, log).init(
			newFitnessPollInterval: fitnessPollInterval,
			newListenSynth: listenSynth ? defaultListenSynth,
			newLeakCoef:leakCoef,
			newMaxPop: maxPop
		);
	}
	init {|newFitnessPollInterval, newListenSynth, newLeakCoef, newMaxPop|
		fitnessPollInterval = newFitnessPollInterval;
		listenSynth = newListenSynth;
		leakCoef = newLeakCoef;
		maxPop = newMaxPop;
		busAllocator = Allocator.new(nResources:maxPop);
	}
	play {|serverOrGroup, outBus, listenGroup|
		//set server and group using the parent method
		super.play(serverOrGroup, outBus);
		this.listenGroup = listenGroup ?? { Group.after(playGroup);};
		playBusses = Bus.alloc(rate:\audio, server:server, numChannels: maxPop*numChannels);
		fitnessBusses = Bus.alloc(rate:\control, server:server, numChannels: maxPop);
		//re-route some output to the master input
		// could do this with less synths i think
		jackNodes = maxPop.collect({|offset|
			Synth.new(
				PSMCCore.n(numChannels),
				[
					\in, Bus.newFrom(playBusses, offset: offset*numChannels, numChannels: numChannels),
					\out, outBus
				],
				listenGroup
			);
		});
		clock = clock ?? { TempoClock.new(fitnessPollInterval.reciprocal, 1); };
		worker = worker ?? {
			Routine.new({loop {this.updateFitnesses; 1.wait;}}).play(clock);
		};
	}
	free {
		super.free;
		//listenGroup.free;
		//listenGroup = nil;
		//could free the parent group instead.
		jackNodes.do({|node| node.free;});
		clock.stop;
		clock = nil;
		worker = nil;
	}
	decorateIndividualDict {|indDict|
		var offset = busAllocator.alloc;
		indDict.busOffset = offset;
		indDict.playBus = Bus.newFrom(playBusses, offset: offset*numChannels, numChannels: numChannels);
		indDict.fitnessBus = Bus.newFrom(fitnessBusses, offset: offset);
		^indDict;
	}
	actuallyPlayIndividual {|indDict|
		//play the synth to which we wish to listen
		super.actuallyPlayIndividual(indDict);
		//analyse its output by listening to its bus
		//we do this dynamically because listensynths can be expensive
		indDict.listenNode = Synth.new(this.listenSynth,
			this.getListenSynthArgs(indDict),
			listenGroup);
		indDict.phenotype.clockOn;
	}
	getListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\in, indDict.playBus,
			\out, indDict.fitnessBus,
			\active, 1,
			\i_leak, leakCoef];
		^listenArgs;
	}
	freeIndividual {|phenotype|
		var freed = super.freeIndividual(phenotype);
		freed.notNil.if({
			freed.listenNode.free;
			busAllocator.dealloc(freed.busOffset);
		});
		^freed;
	}
	updateFitnesses {
		all.keysValuesDo({|key, indDict|
			var updater = {|val|
				var localIndDict = indDict;
				// [\updating, indDict.phenotype.chromosomeAsSynthArgs, \to, val, \insteadof, indDict.fitnessBus.getSynchronous].postln;
				log.log(\updating, indDict.phenotype.chromosomeAsSynthArgs, localIndDict.fitnessBus, \to, val, \insteadof, localIndDict.phenotype.chromosomeAsSynthArgs, localIndDict.fitnessBus );
				island.setFitness(localIndDict.phenotype, val);
				localIndDict.phenotype.incAge;
			};
			indDict.fitnessBus.get(updater);
		});
	}
}

PSCompareSynthController : PSListenSynthController {
	/* This evolutionary listener compares the agents against an incoming
	(external?) signal and allocates fitness accordingly. */
	
	classvar <>defaultListenSynth = \_ga_judge_fftmatch;
	var <>templateBus;
	
	play {|serverOrGroup, outBus, listenGroup, templateBus|
		super.play(serverOrGroup, outBus, listenGroup);
		this.templateBus = templateBus;
	}
	getListenSynthArgs{|indDict|
		^super.getListenSynthArgs(indDict).addAll([
			\targetbus, indDict.templateBus
		]);
	}
	decorateIndividualDict {|indDict|
		super.decorateIndividualDict(indDict);
		indDict.templateBus = templateBus;
		^indDict;
	}
}