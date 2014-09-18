/*
* TODO:
* allow access to raw inputs as outputs with soloing etc
*/
(
var state = ();
MIDIClient.init;
MIDIClient.destinations;
~s = state;
state.make({
	m = PSMetaParamMap.new(inDims:6, outDims:22);
	t = PSParamForwarder(m, 0.05, MIDIOut.newByName("IAC-Driver", "Bus 1"),);
	~m = m;
	~t = t;
	~basenote = 64;
	~intervals = [-7, -5, -4, -3, 0, 3, 4, 5, 7];
	~p1 = 0.5;
	~p2 = 0.5;
	~p3 = 0.5;
	~p4 = 0.5;
	~masterset = IdentitySet.new;
	~subsets = List.new;
	~clock = TempoClock.default;
	~watcher = nil;
});
OSCdef.new(\wiipry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	state.m.set(0, pitch, 0.0, 1.0);
	state.m.set(1, roll, 0.0, 1.0);
	state.m.set(2, yaw, 0.0, 1.0);
	}, "/wii/1/accel/pry", srcID: nil, recvPort:8332);
// Have to set up disposal logic when using custom port or sclang implodes
CmdPeriod.doOnce({ OSCdef(\wiipry).free });
OSCdef.new(\wiinunchukpry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	state.m.set(3, pitch, 0.0, 1.0);
	state.m.set(4, roll, 0.0, 1.0);
	state.m.set(5, yaw, 0.0, 1.0);
	}, "/wii/1/nunchuk/accel/pry", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiipry).free });
OSCdef.new(\wiiplus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(m.phi + 0.001953125);
}, "/wii/1/button/Plus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiplus).free });
OSCdef.new(\wiiminus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(m.phi - 0.001953125);
}, "/wii/1/button/Minus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiminus).free });

state.watcher = Routine({
	inf.do({

		0.25.yield;
	});
}).play(state.clock);

t.addUpdater({}, 0);
t.addUpdater({}, 1);
t.addUpdater({}, 2);
t.addUpdater({}, 3);
t.addUpdater({}, 4);
t.addUpdater({}, 5);

//addMIDICCUpdater {|chan=0, cc=0, i=nil, mididest=nil|
t.addMIDICCUpdater(0, 5, 6);
t.addMIDICCUpdater(0, 6, 7);
t.addMIDICCUpdater(0, 7, 8);
t.addMIDICCUpdater(0, 8, 9);
t.addMIDICCUpdater(0, 9, 10);
t.addMIDICCUpdater(0, 10, 11);
t.addMIDICCUpdater(0, 11, 12);
t.addMIDICCUpdater(0, 12, 13);
t.addMIDICCUpdater(0, 13, 14);
t.addMIDICCUpdater(0, 14, 15);
t.addMIDICCUpdater(0, 15, 16);
t.addMIDICCUpdater(0, 16, 17);
t.addMIDICCUpdater(0, 17, 18);
t.addMIDICCUpdater(0, 18, 19);
t.addMIDICCUpdater(0, 19, 20);
t.addMIDICCUpdater(0, 20, 21);
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
t.solo(8);
t.solo(9);
t.solo(10);
t.solo(11);
t.solo(12);
t.solo(13);
t.solo(14);
t.solo(15);
t.solo(16);
t.solo(17);
t.solo(18);
t.solo(19);
t.solo(20);
t.solo(21);

t.tutti;

m.next;
m.phi_(0.4);

