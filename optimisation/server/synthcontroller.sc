/*
(
//How the controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSSynthController.new(s, ~globalOuts);
~ind = PSSynthDefPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthDefPhenotype.newRandom)});
~control.all.do({|a,b,c| [a,b,c].postln;});
)
*/
PSSynthController {
	/*pass all server instructions through this guy to allow them
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
	var <log;
	//we stash bonus bus information here
	var <>extraSynthArgs;
	var <>outbus;
	var <server;
	var <all;
	var <playGroup;
	var <playing = false;
	var <optimizer;

	*new {|numChannels=1, log|
		^super.newCopyArgs(numChannels, log ?? NullLogger.new).init;
	}
	init {
		all = IdentityDictionary.new(1000);
		extraSynthArgs = [];
	}
	play {|serverOrGroup, outbus ... argz|
		var setupBundle;
		serverOrGroup.isNil.if({"need a target".throw;});
		serverOrGroup.isKindOf(Group).if(
			{
				server = serverOrGroup.server;
				playGroup = serverOrGroup;
			}, {
				server = serverOrGroup;
				playGroup = Group.head(server);
			}
		);
		setupBundle = server.makeBundle(
			false,
			{this.prPlayBundle(server, outbus, *argz);}
		);
		log.log(msgchunks: [setupBundle], tag: \bundling);
		server.listSendBundle(nil, setupBundle);
		playing = true;
	}
	prPlayBundle {|serverOrGroup, outbus ... argz|
		this.outbus = outbus ?? { Bus.audio(server, numChannels)};
	}
	prConnect {|newOptimizer|
		//couple to an optimizer
		optimizer = newOptimizer;
	}
	playIndividual {|phenotype|
		var indDict;
		playing.not.if({"Controller is not playing!".throw});
		indDict = (\phenotype: phenotype);
		all.put(indDict.phenotype.identityHash, indDict);
		try {
			this.prDecorateIndividualDict(indDict);
			log.log(msgchunks: [\ind, indDict], tag: \controlling, priority: -1);
		} { |error|
			switch(error.species.name)
			 	{ 'OutOfResources' } {
					log.log(msgchunks: [error.errorString], tag: \resource_exhausted);
					error.errorString.warn;
					^nil;
				}
			 	// default condition: unhandled exception, rethrow
			 	{ error.throw }
		};
		this.prActuallyPlayIndividual(indDict);
		^indDict;
	}
	prActuallyPlayIndividual {|indDict|
		// we inject extraSynthArgs in here at initialisation to allow for global buses etc
		var synthArgs = this.prGetSynthArgs(indDict);
		log.log(
			msgchunks: [\synthargs] ++ synthArgs ++ extraSynthArgs,
			tag: \controlling);
		indDict.playNode = Synth.new(
			indDict.phenotype.synthDef,
			synthArgs ++ extraSynthArgs,
			target: playGroup
		);
		indDict.phenotype.clockOn;
	}
	updateIndividual {|phenotype|
		var indDict;
		// we do not inject extraSynthArgs here; they are presumed already set
		playing.not.if({"Controller is not playing!".throw});
		indDict = all.at(phenotype.identityHash);
		log.log(msgchunks:[\update_synth_args] ++ phenotype.chromosomeAsSynthArgs,
			tag:\controlling);
		indDict.playNode.set(*(phenotype.chromosomeAsSynthArgs));
		^indDict;
	}
	prDecorateIndividualDict {|indDict|
		indDict.playBus = outbus;
	}
	prGetSynthArgs {|indDict|
		var playArgs;
		playArgs = [\outbus, indDict.playBus, \gate, 1] ++ indDict.phenotype.chromosomeAsSynthArgs;
		^playArgs;
	}
	freeIndividual {|phenotype|
		var freed;
		freed = all.removeAt(phenotype.identityHash);
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
	setAll{|key, val|
		//set a synth value for all  the sundry playthings
		// this is presumed to be a synth value *not* controlled by chromosme, and
		// updates will not propgate therein
		all.values.do({|i|
			i.playNode.set(key, val);
		});
	}
}

/*
(
//How the listening controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthController.new(s, ~globalOuts);
~ind = PSSynthDefPhenotype.newRandom;
~control.playIndividual(~ind);
~control.freeIndividual(~ind);
~ind.mappedArgs
~ind.identityHash;
~ind.chromosome;
10.do({~control.playIndividual(PSSynthDefPhenotype.newRandom)});
~control.all.do({|a,b,c| [a,b,c].postln;});
)
*/
PSListenSynthController : PSSynthController {
	/*
	This Controller subclass sets up Synths and listeners to those synths
	simultaneously.
	*/
	var <fitnessPollRate;
	var <>listenGroup;
	var <>worker;
	var <>clock;
	var <>listenSynthDef;
	var <>leakCoef;
	var <busAllocator;
	var <maxPop;

	var <fitnessBusses;
	var <playBusses;
	var <jackNodes;

	//Toy example synth
	classvar <>defaultListenSynthDef = \ps_listen_eight_hundred;

	*new {|numChannels=1, log, fitnessPollRate=1, listenSynthDef, leakCoef=0.5, maxPop=40|
		^super.new(numChannels, log).init(
			newFitnessPollRate: fitnessPollRate,
			newListenSynth: listenSynthDef ? defaultListenSynthDef,
			newLeakCoef:leakCoef,
			newMaxPop: maxPop
		);
	}
	init {|newFitnessPollRate, newListenSynth, newLeakCoef, newMaxPop|
		super.init;
		fitnessPollRate = newFitnessPollRate;
		listenSynthDef = newListenSynth;
		leakCoef = newLeakCoef;
		maxPop = newMaxPop;
		busAllocator = Allocator.new(nResources:maxPop);
	}
	fitnessPollRate_ {|val|
		fitnessPollRate = val;
		clock.notNil.if({clock.tempo=val;});
	}
	play {|serverOrGroup, outbus, listenGroup|
		//set server and group using the parent method
		super.play(serverOrGroup, outbus, listenGroup);
		clock = clock ?? { TempoClock.new(fitnessPollRate, 1); };
		worker = worker ?? {
			Routine.new({loop {
				this.updateFitnesses;
				1.wait;
			}}).play(clock);
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
	prPlayBundle {|serverOrGroup, outbus, listenGroup|
		//set server and group using the parent method
		super.prPlayBundle(serverOrGroup, outbus);
		listenGroup = listenGroup ?? { Group.after(playGroup);};
		this.listenGroup = listenGroup;
		//these next 2 don't seem to do anything server-side. Huh.
		playBusses = Bus.alloc(rate:\audio, server:server, numChannels: maxPop*numChannels);
		fitnessBusses = Bus.alloc(rate:\control, server:server, numChannels: maxPop);
		//re-route some output to the master input
		// could do this with less synths i think
		jackNodes = maxPop.collect({|offset|
			Synth.new(
				PSMCCore.n(numChannels),
				[
					\inbus, Bus.newFrom(playBusses, offset: offset*numChannels, numChannels: numChannels),
					\outbus, outbus
				],
				target: listenGroup
			);
		});
	}
	prDecorateIndividualDict {|indDict|
		var offset;
		offset = busAllocator.alloc;
		offset.isNil.if({
			OutOfResources.new("out of busses"+ busAllocator).throw;
		});
		indDict.busOffset = offset;
		indDict.playBus = Bus.newFrom(playBusses, offset: offset*numChannels, numChannels: numChannels);
		indDict.fitnessBus = Bus.newFrom(fitnessBusses, offset: offset);
		^indDict;
	}
	prActuallyPlayIndividual {|indDict|
		var listenSynthArgs;
		listenSynthArgs = this.prGetListenSynthArgs(indDict);
		log.log(msgchunks: [\listenSynthArgs] ++ listenSynthArgs, tag: \controlling, priority: -1);
		//play the synth to which we wish to listen
		super.prActuallyPlayIndividual(indDict);
		//analyse its output by listening to its bus
		//we do this dynamically because listensynths can be expensive
		indDict.listenNode = Synth.new(
			this.listenSynthDef,
			listenSynthArgs,
			target: listenGroup);
		indDict.phenotype.clockOn;
	}
	prGetListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\observedbus, indDict.playBus,
			\outbus, indDict.fitnessBus,
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
				log.log(msgchunks: [\updating] ++ localIndDict.phenotype.chromosomeAsSynthArgs ++ [\to, val],
					tag: \controlling, priority: -1);
				log.log(msgchunks: [\using, indDict.fitnessBus, \insteadof, localIndDict.fitnessBus],
					tag: \controlling,  priority: -1);
				optimizer.notNil.if({optimizer.setFitness(localIndDict.phenotype, val);});
				localIndDict.phenotype.incAge;
			};
			indDict.fitnessBus.get(updater);
		});
	}
}

PSCompareSynthController : PSListenSynthController {
	/* This evolutionary listener compares the agents against an incoming
	(external?) signal and allocates fitness accordingly. */

	classvar <>defaultListenSynthDef = \ps_judge_fftmatch;
	var <>targetbus;

	play {|serverOrGroup, outbus, listenGroup, targetbus|
		this.targetbus = targetbus;
		super.play(serverOrGroup, outbus, listenGroup);
	}
	prGetListenSynthArgs{|indDict|
		^super.prGetListenSynthArgs(indDict).addAll([
			\targetbus, indDict.targetbus
		]);
	}
	prDecorateIndividualDict {|indDict|
		super.prDecorateIndividualDict(indDict);
		indDict.targetbus = targetbus;
		^indDict;
	}
}