Allocator {
	/*Manage a bunch of resources using a FIFO */
	var <nResources;
	var <toAlloc;
	var <toFree;
	*new{|nResources=16|
		^super.newCopyArgs(nResources).init;
	}
	init {
		toAlloc = LinkedList.new;
		toFree = IdentitySet.new;
		nResources.do({|i| toAlloc.add(i)});
	}
	alloc {
		var next = toAlloc.popFirst;
		toFree.add(next);
		^next;
	}
	dealloc {|i|
		toAlloc.add(i);
		toFree.remove(i);
	}
}

BusAllocator : Allocator {
	/*Manage a list of multichannel buses*/
	var <nChans;
	var <server;
	var <busArray;
	
	play {|serverOrBusArray, numChannels, busRate=\audio|
		nChans = numChannels;
		serverOrBusArray.isKindOf(Server).if({
			server = serverOrBusArray;
			busArray = Bus.alloc(rate: busRate, server: server, numChannels: nResources*nChans);
		}, {
			server = serverOrBusArray.server;
			busArray = serverOrBusArray;
		});
	}
	free {
		busArray.free;
	}
	alloc {
		^Bus.newFrom(busArray, offset: super.alloc, numChannels: nChans);
	}
	dealloc {|i|
		super.dealloc((i.index-busArray.index)/nChans);
	}
	
}
