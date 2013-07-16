(
//GO!
~touchCoords = IdentityDictionary.new;
~touchesToStart = IdentitySet.new;
~touchesToStop = IdentitySet.new;

~tuioSetterFn = {|message, time, add, port|
	var blobId, coords;
	blobId = message[2];
	coords = message.copyRange(3,message.size);
	~touchCoords[blobId] = coords;
};
~tuioAliverFn = {|message, time, add, port|
	//This one just has to kill dead blobs
	var prevLiving, nowLiving;
	nowLiving = message.copyRange(2,message.size).as(IdentitySet);
	prevLiving = ~touchCoords.keys.as(IdentitySet);
	~touchesToStop = (prevLiving-nowLiving);
	~touchesToStart = (nowLiving-prevLiving);
};
~tuioWorkerFn = {|message, time, add, port|
	//message.postln;
	//Called after frame updates. work should happen here.
	(~touchesToStop.size>0).if({["Stop", ~touchesToStop].postln;});
	~touchesToStop.do({|k|
		~touchCoords.removeAt(k);
	});
	(~touchesToStart.size>0).if({["Start", ~touchesToStart].postln;});
	~touchesToStop.makeEmpty;
	~touchesToStart.makeEmpty;
};
OSCdef.newMatching(\touchset, ~tuioSetterFn, "/tuio/2Dcur", recvPort: 3333, argTemplate:["set"]);
OSCdef.newMatching(\touchalive, ~tuioAliverFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["alive"]);
OSCdef.newMatching(\touchupdate, ~tuioWorkerFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["fseq"]);
)
(
//STOP!
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
OSCdef(\touchupdate).free;
)
