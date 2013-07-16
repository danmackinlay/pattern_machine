//SETO doesn't seem to do anything. I can't be fucked working out why
//t = SETOServer('2Dobj', SETOdump);
//u = SETO_OSCTUIOServer('2Dobj',NetAddr("127.0.0.1", 3333), SETOdump);
//u.gui
(
~touches = IdentityDictionary.new;
~tuioSetterFn = {|message, time, add, port|
	message.postln
};
~tuioAliverFn = {|message, time, add, port|
	var living = message.copyRange(2,message.size).as(IdentitySet);
	//living.postln;
	~touches.keys.do({|k|
		["scanning",k].postln;
		living.scanFor(k).not.if({
			["deleting",k].postln;
			~touches.removeAt(k);
		}, {["keeping",k].postln;});
	});
};
// OSCdef.newMatching(\touchset, ~tuioSetterFn, "/tuio/2Dcur", recvPort: 3333, argTemplate:["set"]);
OSCdef.newMatching(\touchalive, ~tuioAliverFn, "/tuio/2Dcur", recvPort: 3333, argTemplate:["alive"]);
)
(
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
)
[1,2,3,4].copyRange(2,4)