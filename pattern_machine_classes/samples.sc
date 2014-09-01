/*
TODO: this should probably handle initing with some kind of semaphore thing to be graceful about forked threads and unbooted servers.
TODO: handle a class library of sample sets that I use a lot
TODO: put fade-outs in sound files
 */
PSSamples {
	var <n;
	var <dur;
	var <chans;
	var <>basePath;
	var <server;
	var <durSamples;
	var <sampleBufArray;
	var <sampleBufKeys;
	var <inited=false;
	var <bufPtr;
	//handle a sample library, of bounded maximum size in cardinality and length
	*new {|n=64, dur=10, chans=1, basePath, server|
		^super.newCopyArgs(n, dur, chans, basePath, server ? Server.default)
	}
	init {
		inited.if({this.free});
		durSamples = server.sampleRate;
		sampleBufKeys = IdentityDictionary.new;
		bufPtr = -1;
		{
			inited = true;
			sampleBufArray = Buffer.allocConsecutive(
				n, server,
				durSamples,
				chans
			);
			server.sync;
		}.forkIfNeeded;
	}
	initFromDict {|dictOfPaths|
		{
			this.init;
			server.sync;
			this.loadDict(dictOfPaths)
		}.forkIfNeeded;
	}
	loadDict{|dictOfPaths|
		dictOfPaths.keysValuesDo({|key,paths|
			paths.do({|path|
				this.loadPath(path, key);
			});
		});
	}
	loadPath {|path, key="", ind|
		var buf, fullpath, sublist;
		sublist = sampleBufKeys[key] ?? {Array.new};
		fullpath = path;
		basePath.notNil.if({fullpath = basePath +/+ path});
		ind = ind ?? {bufPtr = bufPtr+1};
		sampleBufKeys[key] = sublist.add(ind);
		buf = sampleBufArray[ind];
		buf.readChannel(fullpath, channels: Array.series(chans));
		^ind;
	}
	at {|ind|
		^sampleBufArray[ind];
	}
	key {|key, ind|
		^sampleBufArray[sampleBufKeys[key].wrapAt(ind)];
	}
	keyChoose {|key, ind|
		^sampleBufArray[sampleBufKeys[key].choose];
	}
	free {
		sampleBufArray.do({|buf| buf.free});
		inited=false;
	}
}