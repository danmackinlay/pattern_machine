/*
(
//How the controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSSwarmController.new(s, ~globalOuts);
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
PSSwarmController {
	/*pass all server instructions through this guy to allow the instructions
	to be delivered in the right order and the boring bus/server allocation
	details to be abstracted away, and to track resources needing freeing.*/
	
	/*Instance vars are all public to aid debugging, but not much use to look 
	at unless you *are* debugging.*/
	var <outBus;
	var <numChannels;
	var <server;
	var <all;
	var <playGroup;
	*new {|server, numChannels=1|
		^super.newCopyArgs(numChannels).init(server);
	}
	init {|serverOrGroup|
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
	playIndividual {|phenotype|
		var indDict;
		indDict = (\phenotype: phenotype);
		all.put(indDict.phenotype.identityHash, indDict);
		this.decorateIndividualDict(indDict);
		this.loadIndividualDict(
			indDict
		);
		this.actuallyPlayIndividual(indDict);
	}
	loadIndividualDict{|indDict|
		//pass
	}
	decorateIndividualDict {|indDict|
		indDict.playBus = outBus;
	}
	actuallyPlayIndividual {|indDict|
		//private
		indDict.playNode = indDict.phenotype.asSynth(
			out:indDict.playBus, group:playGroup
		);
		indDict.phenotype.clockOn;
	}
	freeIndividual {|phenotype|
		var freed;
		freed = all.removeAt(phenotype.identityHash);
		freed.isNil.not.if({
			//these should be separated, or the second eliminated by the first.
			freed.phenotype.stop(freed.playNode);//closes envelope
			freed.playNode.free;//forces synth to free
		});
		^freed;
	}
	free {
		all.do({|i| this.freeIndividual(i.phenotype);});
	}
}


/*
(
//How the listening controller works, nuts-and-bolts
s=Server.default;
~globalOuts = Bus.new(\audio, 0, 2);
~control = PSListenSynthSwarmController.new(s, ~globalOuts);
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
PSListenSynthSwarmController : PSSwarmController {
	/* Handle a number of simultaneous synths being digitally listened to
	*/
	var <fitnessPollInterval;
	var <listenGroup;
	var <worker;
	classvar <listenNode = \ps_listen_eight_hundred;
	*new {|server, bus, numChannels=1, fitnessPollInterval=1|
		^super.newCopyArgs(bus, numChannels).init(
			server, fitnessPollInterval);
	}
	init {|serverOrGroup, thisFitnessPollInterval|
		var clock;
		super.init(serverOrGroup);
		fitnessPollInterval = thisFitnessPollInterval;
		listenGroup = Group.after(playGroup);
		clock = TempoClock.new(fitnessPollInterval.reciprocal, 1);
		worker = Routine.new({loop {this.updateFitnesses; 1.wait;}}).play(clock);
	}
	decorateIndividualDict {|indDict|
		indDict.playBus = Bus.audio(server, numChannels);
		indDict.listenBus = Bus.control(server, 1);
		^indDict;
	}
	actuallyPlayIndividual {|indDict|
		//play the synth to which we wish to listen
		indDict.playNode = indDict.phenotype.asSynth(
			out:indDict.playBus, group:playGroup);
		//analyse its output by listening to its bus
		indDict.listenNode = Synth(this.class.listenNode,
			this.getListenSynthArgs(indDict),
			listenGroup);
		indDict.phenotype.clockOn;
		//re-route some output to the master input
		indDict.jackNode = Synth(PSMCCore.n(numChannels),
			[\in, indDict.playBus, \out, outBus],
			listenGroup);
	}
	getListenSynthArgs{|indDict|
		var listenArgs;
		listenArgs = [\in, indDict.playBus, \out, indDict.listenBus, \active, 1, \i_leakcoef, 1.0];
		^listenArgs;
	}
	freeIndividual {|phenotype|
		var freed = super.freeIndividual(phenotype);
		freed.isNil.not.if({
			freed.playBus.free;
			freed.listenBus.free;
			freed.listenNode.free;
			freed.jackNode.free;
		});
		^freed;
	}
	updateFitnesses {
		all.keysValuesDo({|key, indDict|
			indDict.listenBus.get({|val|
				indDict.phenotype.fitness = val;
			});
			indDict.phenotype.incAge;
		});
	}
}
