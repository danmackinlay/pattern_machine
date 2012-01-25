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
	going to rank them manually or something as per Dan Stowell's neat GOAD.sc
	
	A subclass, PSListenSynthController, handles setting up candidate
	phenosynths and listeners simultaneously.
	*/
	
	/*Instance vars are all public to aid debugging, but not much use to look 
	at unless you *are* debugging.*/
	var <outBus;
	var <numChannels;
	var <server;
	var <all;
	var <playGroup;
	var <allocatedNodes;
	var <freedNodes;
	var playing = false;
	
	*new {|server, numChannels=1|
		^super.newCopyArgs(numChannels).init(server);
	}
	init {|serverOrGroup|
		allocatedNodes = IdentityDictionary.new;
		freedNodes = List.new;
		all = IdentityDictionary.new;
		serverOrGroup.isKindOf(Group).if(
			{
				server = serverOrGroup.server;
				playGroup = serverOrGroup;
			}, {
				server = serverOrGroup;
				playGroup = Group.head(server);
			}
		);
		outBus ?? {outBus = Bus.audio(server, numChannels)};
	}
	play {
		//This ONLY sets a flag to allow playing of synths, so that we don't end
		//up with concurrency problems with playing/freeing
		playing = true;
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
			indDict.phenotype.class.synthdef,
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
		freed.isNil.not.if({
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
	var <fitnessPollInterval;
	var <listenGroup;
	var <worker;
	var <clock;
	
	//Toy 
	classvar <listenSynth = \ps_listen_eight_hundred;
	*new {|server, bus, numChannels=1, fitnessPollInterval=1|
		^super.newCopyArgs(bus, numChannels).init(
			server, fitnessPollInterval);
	}
	init {|serverOrGroup, thisFitnessPollInterval|
		super.init(serverOrGroup);
		fitnessPollInterval = thisFitnessPollInterval;
	}
	play {
		listenGroup = listenGroup ?? { Group.after(playGroup);};
		clock = clock ?? { TempoClock.new(fitnessPollInterval.reciprocal, 1); };
		worker = worker ?? {
			Routine.new({loop {this.updateFitnesses; 1.wait;}}).play(clock);
		};
		super.play;
	}
	free {
		super.free;
		//listenGroup.free;
		//listenGroup = nil;
		clock.stop;
		clock = nil;
		worker = nil;
	}
	decorateIndividualDict {|indDict|
		indDict.playBus = Bus.audio(server, numChannels);
		indDict.listenBus = Bus.control(server, 1);
		^indDict;
	}
	actuallyPlayIndividual {|indDict|
		//play the synth to which we wish to listen
		//NB - I suspect this routine of having concurrency problems at high load.
		super.actuallyPlayIndividual(indDict);
		//analyse its output by listening to its bus
		indDict.listenNode = Synth.new(this.class.listenSynth,
			this.getListenSynthArgs(indDict),
			listenGroup);
		indDict.phenotype.clockOn;
		//re-route some output to the master input
		indDict.jackNode = Synth.new(PSMCCore.n(numChannels),
			[\in, indDict.playBus, \out, outBus],
			listenGroup);
	}
	getListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\in, indDict.playBus, \out, indDict.listenBus, \active, 1, \i_leakcoef, 0.9];
		^listenArgs;
	}
	freeIndividual {|phenotype|
		var freed = super.freeIndividual(phenotype);
		freed.isNil.not.if({
			freed.listenNode.free;
			freed.playBus.free;
			freed.listenBus.free;
			freed.jackNode.free;
		});
		^freed;
	}
	updateFitnesses {
		all.keysValuesDo({|key, indDict|
			indDict.listenBus.get({|val|
				//[\updating, key, \to, val].postln;
				indDict.phenotype.fitness = val;
			});
			indDict.phenotype.incAge;
		});
	}
}

PSCompareSynthController : PSListenSynthController {
	/* This evolutionary listener compares the agents against an incoming
	(external?) signal and allocates fitness accordingly. */
	
	classvar <listenSynth = \_ga_judge_fftmatch;
	var <templateBus;
	
	*new {|server, bus, numChannels=1, fitnessPollInterval=1, templateBus|
		var noob;
		noob = super.newCopyArgs(bus, numChannels);
		noob.init(
			server, fitnessPollInterval, templateBus);
		^noob;
	}
	init {|serverOrGroup, thisFitnessPollInterval, thisTemplateBus|
		super.init(serverOrGroup, thisFitnessPollInterval);
		templateBus = thisTemplateBus;
		
	}
	
	getListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\in, indDict.playBus,
			\out, indDict.listenBus,
			\templatebus, indDict.templateBus,
			\active, 1,
			\i_leakcoef, 0.9];
		^listenArgs;
	}
	decorateIndividualDict {|indDict|
		super.decorateIndividualDict(indDict);
		indDict.templateBus = templateBus;
		^indDict;
	}
}