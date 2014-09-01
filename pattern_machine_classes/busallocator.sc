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
		next.notNil.if({
			//should I throw an exception in this case?
			toFree.add(next);
		}, {
			//throw exception?
		});
		^next;
	}
	dealloc {|i|
		toFree.findMatch(i).notNil.if({
			toFree.remove(i);
			toAlloc.add(i);
		}, {
			//throw exception?
		});
	}
	printOn { arg stream;
		stream << this.class.asString <<"(nResources:" << nResources.asString << ", available:" << toAlloc.asString << ")";
	}
}

BusAllocator : Allocator {
	/*Manage a list of multichannel buses using a FIFO*/
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
