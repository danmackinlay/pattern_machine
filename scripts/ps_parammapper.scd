/*
* TODO:
* Find MIDI mapping for
* Mod wheel (CC0)
* foot controller (CC4)
  * aftertouch
  * off vel
  * pitch bend
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
t.addMIDICCUpdater(0, 5, 0);
t.addMIDICCUpdater(0, 6, 1);
t.addMIDICCUpdater(0, 7, 2);
t.addMIDICCUpdater(0, 8, 3);
t.addMIDICCUpdater(0, 9, 4);
t.addMIDICCUpdater(0, 10, 5);
t.addMIDICCUpdater(0, 11, 6);
t.addMIDICCUpdater(0, 12, 7);
)
t.solo(0);
t.solo(1);
t.solo(2);
t.solo(3);
t.solo(4);
t.solo(5);
t.solo(6);
t.solo(7);

t.tutti;

m.next;
m.phi_(0.4);
