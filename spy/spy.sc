/* A stethoscope.
This guy listens to a a given bus at a given point in the node order.
It probably duplicates ScopeOut, but that is undocumented,
and this use is straightforward.
*/

SpyBus {
	var <>server;
	var <>listenBus;
	var <>spyBus;
	var <>target;
	var <>scope;
	var <>listenerNode;

	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		/* Simplest synth ever. Taps one bus to another.
		We do this with a synth so we can spy on interesting places in execution order
		*/
		SynthDef.new(\spy_guy, { |inbus, outbus|
			ReplaceOut.ar(outbus, In.ar(inbus));
		}).add;
	}
	play {|target, listenBus, spyBus, addAction=\addAfter|
		server = target.isKindOf(Server).if({target}, {target.server});
		target = target.asTarget;
		this.target = target;
		listenBus = listenBus.asBus;
		this.listenBus = listenBus;
		spyBus = spyBus ? Bus.audio(server, numChannels: 1);
		this.spyBus = spyBus;
		listenerNode = Synth.new(\spy_guy, [\inbus, listenBus, \outbus, spyBus], target: target, addAction: \addAfter);
		{scope = spyBus.scope}.defer;
	}
	listenTo {|bus|
		listenBus = bus.asBus;
		listenerNode.set(\inbus, listenBus);
		^this;
	}
	moveAfter {|aNode| listenerNode.moveAfter(aNode);}
	moveBefore {|aNode| listenerNode.moveBefore(aNode);}
	moveToHead {|aNode| listenerNode.moveToHead(aNode);}
	moveToTail {|aNode| listenerNode.moveToTail(aNode);}

}