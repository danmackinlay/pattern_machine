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
var state = ();
~state = state;
~state.m = m = PSMetaParamMap.new(inDims:6, outDims:16);
m.plot;
MIDIClient.init;
MIDIClient.destinations;
t = PSParamForwarder(m, 0.05, MIDIOut.newByName("IAC-Driver", "Bus 1"),);
OSCdef.new(\wiipry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	m.set(0, pitch, 0.0, 1.0);
	m.set(1, roll, 0.0, 1.0);
	m.set(2, yaw, 0.0, 1.0);
	}, "/wii/1/accel/pry", srcID: nil, recvPort:8332);
// Have to set up disposal logic when using custom port or sclang implodes
CmdPeriod.doOnce({ OSCdef(\wiipry).free });
OSCdef.new(\wiinunchukpry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	m.set(3, pitch, 0.0, 1.0);
	m.set(4, roll, 0.0, 1.0);
	m.set(5, yaw, 0.0, 1.0);
	}, "/wii/1/nunchuk/accel/pry", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiipry).free });
OSCdef.new(\wiiplus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	m.phi_(m.phi + 0.001953125);
}, "/wii/1/button/Plus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiplus).free });
OSCdef.new(\wiiminus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	m.phi_(m.phi - 0.001953125);
}, "/wii/1/button/Minus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiminus).free });

t.addMIDICCUpdater(0, 5, 0);
t.addMIDICCUpdater(0, 6, 1);
t.addMIDICCUpdater(0, 7, 2);
t.addMIDICCUpdater(0, 8, 3);
t.addMIDICCUpdater(0, 9, 4);
t.addMIDICCUpdater(0, 10, 5);
t.addMIDICCUpdater(0, 11, 6);
t.addMIDICCUpdater(0, 12, 7);
)
m.inParams;
m.outParams;
m.phi=0.11;

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
