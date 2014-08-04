/*

*/
(
m = PSMetaParamMap.new(inDims:3, outDims:10);
MIDIClient.init;
MIDIClient.destinations;
t = PSParamForwarderMIDI(m, 0.05, MIDIOut.newByName("IAC-Driver", "Bus 1"),);
OSCdef.new(\wii, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	m.set(0, pitch, 0.0, 1.0);
	m.set(1, roll, 0.0, 1.0);
	m.set(2, yaw, 0.0, 1.0);
	}, "/wii/1/accel/pry", nil, 8332);
// Have to set up disposal logic when using custom port or sclang implodes
CmdPeriod.doOnce { OSCdef(\wii).free };
t.addMIDIUpdater(0, 5, 0);
t.addMIDIUpdater(0, 6, 1);
t.addMIDIUpdater(0, 7, 2);
)
t.solo(0);


m.next;
m.phi_(0.4);
