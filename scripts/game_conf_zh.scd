/*
* TODO:
* allow access to raw inputs as outputs with soloing etc
* note density and velocity from accel
* emergency midi flush
* stateful MIDI note bucket handling noteoff and transposes
* accel does something meaningful
* use cross and joystick, even if only indirectly
* individual mute control for increasing complexity
*/

(
var state = ();
MIDIClient.init;
MIDIClient.destinations;
~s = state;
state.make({
	~mididest = MIDIOut.newByName("IAC-Driver", "Bus 1");
	m = PSSemiOrderlyMetaParamMap.new(inDims: 12, outDims:30);
	t = PSParamForwarder(m, 0.05, ~mididest);
	~oscdefs = List.new;
	// Have to set up disposal logic when using custom port or sclang implodes
	CmdPeriod.doOnce({ state.oscdefs.do({|def| def.free }) });
	~m = m;
	{state.m.plot}.defer;
	~t = t;
	~active = true;
	~gainrate = 0.1; // up/down scale/beat
	~gainratescale = 1.0; // up/down scale/beat
	~gaindeltas = Array.fill(4, -1.0);
	~gains = Array.fill(4, 0.0);
	~basenote = 64;
	~intervals = [-7, -5, -4, -3, 0, 3, 4, 5, 7];
	~intP = [0.5, 0.5, 0.5, 0.5, 0.5];
	~masterset = IdentitySet.new;
	//~subsets = List.new;
	~clock = TempoClock.default;
	~pollint = 0.025;
	//octaves and note subsets?
	~updateintervals = {
		var currnote, nextstep, lastnotes, nextnotes;
		nextnotes = IdentitySet.new;
		lastnotes = state.masterset;
		state.active.if({
			currnote = state.basenote;
			state.intP.do({|p|
				currnote = currnote + state.intervals.unif(p);
				nextnotes = nextnotes.add(currnote);
			});
		});
		(nextnotes != lastnotes).if({[nextnotes].postln;});
		state.masterset = nextnotes;
		//start/stop notes
		(nextnotes-lastnotes).do({|note|
			state.mididest.noteOn(chan:0, note: note, veloc: 64)
		});
		(lastnotes-nextnotes).do({|note|
			state.mididest.noteOff(chan:0, note: note, veloc: 64)
		});
	};
	~updategains = {
		state.gains = (state.gains +
			(state.gaindeltas *
			state.pollint *
			state.gainrate *
			state.gainratescale)
		).clip(0.0, 1.0);
		state.m.set(8, state.gains[0], 0.0, 1.0);
		state.m.set(9, state.gains[1], 0.0, 1.0);
		state.m.set(10, state.gains[2], 0.0, 1.0);
		state.m.set(11, state.gains[3], 0.0, 1.0);
	};

	~watcher = Routine({
		inf.do({
			state.updateintervals.();
			state.updategains.();
			state.pollint.yield;
		});
	}).play(state.clock);
	//kill notes
	CmdPeriod.doOnce({ state.active=false; state.updateintervals();  });
});
~s.oscdefs.add(OSCdef.new(\wiipry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	state.m.set(0, pitch, 0.0, 1.0);
	state.m.set(1, roll, 0.0, 1.0);
	state.m.set(2, yaw, 0.0, 1.0);
	state.m.set(6, accel, 0.0, 1.0);
}, "/wii/1/accel/pry", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiinunchukpry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	state.m.set(3, pitch, 0.0, 1.0);
	state.m.set(4, roll, 0.0, 1.0);
	state.m.set(5, yaw, 0.0, 1.0);
	state.m.set(7, accel, 0.0, 1.0);
	}, "/wii/1/nunchuk/accel/pry", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiiplus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(m.phi + 0.001953125);
}, "/wii/1/button/Plus", srcID: nil, recvPort:8332, argTemplate:[_==1]));
~s.oscdefs.add(OSCdef.new(\wiiminus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(m.phi - 0.001953125);
}, "/wii/1/button/Minus", srcID: nil, recvPort:8332, argTemplate:[_==1]));
~s.oscdefs.add(OSCdef.new(\wiihome, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.active_(state.active.asBoolean.not);
}, "/wii/1/button/Home", srcID: nil, recvPort:8332, argTemplate:[_==1]));
~s.oscdefs.add(OSCdef.new(\wiiA, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.gaindeltas[0] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/button/A", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiiB, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.gaindeltas[1] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/button/B", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiiC, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.gaindeltas[2] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/nunchuk/button/C", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiiZ, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.gaindeltas[3] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/nunchuk/button/Z", srcID: nil, recvPort:8332));
~s.oscdefs.add(OSCdef.new(\wiinunchukjoy, {
	arg msg, time, addr, ports;
	var dummy, x, y;
	# dummy, x, y = msg;
	state.ratescale = y.linexp(0.0,1.0, 1/8, 8);
	//[\xy, x, y, state.ratescale].postln;
	}, "/wii/1/nunchuk/joy", srcID: nil, recvPort:8332));

//direct updaters
t.addUpdater({|v| state.intP[0]=v}, 0);
t.addUpdater({|v| state.intP[1]=v}, 1);
t.addUpdater({|v| state.intP[2]=v}, 2);
t.addUpdater({|v| state.intP[3]=v}, 3);
t.addUpdater({|v| state.intP[4]=v}, 4);
t.addUpdater({|v|}, 3);
t.addUpdater({|v|}, 7);
//addMIDICCUpdater {|chan=0, cc=0, i=nil, mididest=nil|
t.addMIDICCUpdater(0, 5, 8);
t.addMIDICCUpdater(0, 6, 9);
t.addMIDICCUpdater(0, 7, 10);
t.addMIDICCUpdater(0, 8, 11);

//compound vals
t.addMIDICCUpdater(0, 9, 12);
t.addMIDICCUpdater(0, 10, 13);
t.addMIDICCUpdater(0, 11, 14);
t.addMIDICCUpdater(0, 12, 15);
t.addMIDICCUpdater(0, 13, 16);
t.addMIDICCUpdater(0, 14, 17);
t.addMIDICCUpdater(0, 15, 18);
t.addMIDICCUpdater(0, 16, 19);
t.addMIDICCUpdater(0, 17, 20);
t.addMIDICCUpdater(0, 18, 21);
t.addMIDICCUpdater(0, 19, 22);
t.addMIDICCUpdater(0, 20, 23);
t.addUpdater({|v| }, 24);
t.addUpdater({|v| }, 25);
t.addUpdater({|v| }, 26);
t.addUpdater({|v| }, 27);
t.addUpdater({|v| }, 28);
t.addUpdater({|v| }, 29);
t.addUpdater({|v| }, 30);
t.addUpdater({|v| }, 31);
)
~s.active = false;
~s.active = true;
~s.gaindeltas;
~s.gains;
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
