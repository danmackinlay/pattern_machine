Server.default = PS.serverboot.(\local, \builtin);
Server.default = PS.serverboot.(\local, \rme);
Server.default = PS.serverboot.(\local, \motu);
Server.default = PS.serverboot.(\local, \jack);
Server.default = PS.serverboot.(\internal, \builtin);
Quarks.gui;
s.dumpOSC(1);
s.dumpOSC(0);
OSCdef.trace(true);
OSCdef.trace(false);
ServerTreeGui.makeWindow(s);
StartUp.run;
PS.go.();
PS.kill.();
MIDIClient.init;
MIDIFunc.trace(false);
MIDIFunc.trace(true);
MIDIClient.sources;
MIDIClient.init;
MIDIIn.connectAll;
SCDoc.indexAllDocuments;

(
~spy = (
	instrument: \jack__1,
	in: ~state.inbuses[0],
	out: ~state.masteroutbus.subBus(0,1),
	group: ~state.outputgroup,
	server: ~state.server,
	addAction: \addToTail,
	sendGate: false,//persist
).play;
)
~spy.free;
QuickLauncher().front;