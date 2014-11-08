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
	var <>numChannels;
	var <>server;
	var <>busArray;

	*new {|serverOrBusArray, numChannels=1, busRate=\audio, nResources=16|
		var server, busArray;
		//[serverOrBusArray, numChannels, busRate, nResources].postcs;
		serverOrBusArray.isKindOf(Server).if({
			server = serverOrBusArray;
			busArray = Bus.alloc(
				rate: busRate,
				server: server,
				numChannels: nResources*numChannels);
		}, {
			server = serverOrBusArray.server;
			busArray = serverOrBusArray;
			nResources = busArray.numChannels/numChannels;
		});
		//[serverOrBusArray, numChannels, busRate, nResources].postcs;
		
		^super.new(nResources).numChannels_(numChannels).server_(server).busArray_(busArray);
	}
	free {
		busArray.free;
	}
	alloc {
		^Bus.newFrom(busArray, offset: (super.alloc)*numChannels, numChannels: numChannels);
	}
	dealloc {|i|
		super.dealloc((i.index-busArray.index)/numChannels);
	}
}
