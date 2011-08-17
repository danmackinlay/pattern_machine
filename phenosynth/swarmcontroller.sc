PSSwarmController {
	/*pass all server instructions through this guy to allow the instructions
	to be delivered in the right order and the boring bus/server allocation
	details to be abstracted away, and to track resources needing freeing.*/
	
	//Instance vars are all public to aid debugging, but, honestly, don't
	//touch them. Why would you touch them? Don't touch them.
	var <outBus;
	var <numChannels;
	var <q; //i.e. a Queue.
	var <server;
	var <all;
	var <playGroup;
	*new {|server, bus, numChannels=2, q|
		^super.newCopyArgs(bus, numChannels, q).init(server);
	}
	init {|serverOrGroup|
		all = IdentityDictionary.new;
		serverOrGroup.isKindOf(Group).if(
			{
				server = serverOrGroup.server;
				q ?? {q = PSServerQueue.new(server);};
				playGroup = serverOrGroup;
			}, {
				server = serverOrGroup;
				q ?? {q = PSServerQueue.new(server);};
				q.push({playGroup = Group.head(server);});
			}
		);
		outBus ?? {q.push({outBus = Bus.audio(server, numChannels)});};
	}
	playIndividual {|phenotype|
		//this doesn't actually play - it sets up a callback to play
		var indDict;
		indDict = (\phenotype: phenotype);
		all.put(indDict.phenotype.identityHash, indDict);
		q.push({
			this.decorateIndividualDict(indDict);
			this.loadIndividualDict(
				indDict
			);
			this.actuallyPlayIndividual(indDict);
		});
	}
	loadIndividualDict{|indDict|
		all.put(indDict.phenotype.identityHash, indDict);
	}
	decorateIndividualDict {|indDict|
		//this doesn't need to be called in the server queue;
		//but in general, one could so need in, e.g., subclasses.
		indDict.playBus = outBus;
	}
	actuallyPlayIndividual {|indDict|
		//private.
		q.push({
			indDict.playSynth = indDict.phenotype.play(
				out:indDict.playBus, group:playGroup
			);
			indDict.phenotype.clockOn;
		});
	}
	freeIndividual {|phenotype|
		var freed;
		freed = all.removeAt(phenotype.identityHash);
		freed ?? q.push({
			//these should be separated, or the second elimiated by the first.
			freed.phenotype.free;//closes envelope
		  freed.playSynth.free;//forces synth to free
		});
		^freed;
	}
	free {
		all.do({|i| this.freeIndividual(i.phenotype);});
	}
}

PSListenSynthSwarmController : PSSwarmController {
	/* Handle a number of simultaneous synths being digitally listened to
	*/
	var <fitnessPollInterval;
	var <listenGroup;
	var <worker;
	classvar <listenSynth = \ps_listen_eight_hundred;
	*new {|server, bus, numChannels=2, q, fitnessPollInterval=1|
		^super.newCopyArgs(bus, numChannels, q).init(
			server, fitnessPollInterval);
	}
	init {|serverOrGroup, thisFitnessPollInterval|
		var clock;
		super.init(serverOrGroup);
		fitnessPollInterval = thisFitnessPollInterval;
		q.push({listenGroup = Group.after(playGroup);});
		clock = TempoClock.new(fitnessPollInterval.reciprocal, 1);
		worker = Routine.new({loop {this.updateFitnesses; 1.wait;}}).play(clock);
	}
	decorateIndividualDict {|indDict|
		q.push({
			indDict.playBus = Bus.audio(server, numChannels);
			indDict.listenBus = Bus.control(server, 1);
		});
		^indDict;
	}
	actuallyPlayIndividual {|indDict|
		q.push({
			//play the synth to which we wish to listen
			indDict.playSynth = indDict.phenotype.play(
				out:indDict.playBus, group:playGroup);
			//analyse its output by listening to its bus
			indDict.listenSynth = Synth(this.class.listenSynth,
				this.getListenSynthArgs(indDict),
				listenGroup);
			indDict.phenotype.clockOn;
			//re-route some output to the master input
			indDict.jackSynth = Synth(\jack, [\in, indDict.playBus, \out, outBus], listenGroup);
		});
	}
	getListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\in, indDict.playBus, \out, indDict.listenBus, \active, 1, \i_leakcoef, 1.0];
		^listenArgs;
	}
	freeIndividual {|phenotype|
		var freed = super.freeIndividual(phenotype);
		freed ?? q.push({
			freed.listenSynth.free;
			freed.jackSynth.free;
			freed.playBus.free;
			freed.listenBus.free;
		});
		^freed;
	}
	updateFitnesses {
		all.keysValuesDo({|key, indDict|
			//['tick', indDict, key].postln;
			//server cmd, but doesn't need to be queued coz it's read-only.
			indDict.listenBus.get({|val|
				//["got val", val, "for phenotype id", key, "on", indDict.listenBus].postln;
				indDict.phenotype.fitness = val;
			});
		});
	}
}

PSServerQueue {
	/*a queue to service instructions, waiting on sync from a particular server
	
	I know this looks overblown, but it sure does stop the wacky, unpredictable
	explosions I was having before.
	
	On the other hand, this is as slow as hell. Smart bundling would be better.
	*/
	var <server;
	var <fifo;
	var <worker;
	var doneFlag;//internal condition for list servicing
//	var <emptyFlag;//external signal that the list is empty - not implemented
	*new {|server|
		^super.newCopyArgs(server ? Server.default).init;
	}
	init {
		fifo = LinkedList.new;
		doneFlag = Condition.new(false);
		worker = Routine({
			var job, result;
			loop {
				job = fifo.pop;
				job.isNil.if({
					doneFlag.hang;
				}, {
					result = job.value;
					server.sync;
				})
			}
		}).play;
	}
	push {|job|
		fifo.addFirst(job);
		doneFlag.unhang;
	}
	free {
		this.push({this.actuallyFree;});
	}
	actuallyFree {
		worker.free;
		doneFlag.unhang;
	}
}