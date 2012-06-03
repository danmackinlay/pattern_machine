Allocator {
	/*Manage a bunch of resources using a FIFO */
	var nResources;
	var queue;
	*new{|nResources|
		^super.newCopyArgs(nResources).init;
	}
	init {
		queue = LinkedList.new;
		nResources.do({|i| queue.add(i)});
	}
	alloc {
		^queue.popFirst;
	}
	dealloc {|i|
		queue.add(i);
	}
}

BusAllocator : Allocator {
	/*Manage a list of multichannel buses*/
	var nChans;
	var server;
	var busArray;
	
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
