/*
* TODO:
* allow access to raw inputs as outputs with soloing etc
* emergency midi flush
* stateful MIDI note bucket handling noteoff and transposes
* individual mute control for increasing complexity
*/

(
var state = ();
MIDIClient.init;
MIDIClient.destinations;
~s = state;
state.make({
	~mididest = MIDIOut.newByName("IAC-Driver", "Bus 1");
	m = PSSemiOrderlyMetaParamMap.new(inDims: 12, outDims: 56);
	t = PSParamForwarder(m, 0.05, ~mididest);
	// Have to set up disposal logic when using custom port or sclang implodes
	// nb, this doesn't actually work; only OSCdefs manually collected below work.
	CmdPeriod.doOnce({
		OSCdef.freeAll;
	});
	~m = m;
	{state.m.plot}.defer;
	~t = t;
	~active = true;
	~levelrate = 0.1; // up/down scale/beat
	~levelratescale = 1.0; // up/down scale/beat
	~leveldeltas = Array.fill(4, -1.0);
	~levels = Array.fill(4, 0.0);
	~basenote = 64;
	~intervals = [-7, -5, -4, -3, 0, 3, 4, 5, 7];
	~intP = [0.5, 0.5, 0.5, 0.5, 0.5];
	~masterset = IdentitySet.new;
	//~subsets = List.new;
	~clock = TempoClock.default;
	~pollint = 0.03125;
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
		(nextnotes).do({|note|
			state.mididest.noteOn(chan:0, note: note, veloc: 127)
		});
		(lastnotes-nextnotes).do({|note|
			state.mididest.noteOff(chan:0, note: note, veloc: 64)
		});
	};
	~updategains = {
		state.levels = (state.levels +
			(state.leveldeltas *
			state.pollint *
			state.levelrate *
			state.levelratescale)
		).clip(0.0, 1.0);
		state.m.set(8, state.levels[0], 0.0, 1.0);
		state.m.set(9, state.levels[1], 0.0, 1.0);
		state.m.set(10, state.levels[2], 0.0, 1.0);
		state.m.set(11, state.levels[3], 0.0, 1.0);
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
OSCdef.new(\wiipry, {
	arg msg, time, addr, ports;
	var dummy, pitch, roll, yaw, accel;
	# dummy, pitch, roll, yaw, accel = msg;
	//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
	state.m.set(0, pitch, 0.0, 1.0);
	state.m.set(1, roll, 0.0, 1.0);
	state.m.set(2, yaw, 0.0, 1.0);
	state.m.set(6, accel, 0.0, 1.0);
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
	state.m.set(7, accel, 0.0, 1.0);
}, "/wii/1/nunchuk/accel/pry", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiinunchukpry).free });
OSCdef.new(\wiiplus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(state.m.phi + 0.001953125);
}, "/wii/1/button/Plus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiplus).free });
OSCdef.new(\wiiminus, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.phi_(state.m.phi - 0.001953125);
}, "/wii/1/button/Minus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiminus).free });
OSCdef.new(\wiihome, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.active_(state.active.asBoolean.not);
	state.active.if({state.t.tutti}, {state.t.muteAll});
}, "/wii/1/button/Home", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiihome).free });
OSCdef.new(\wiiA, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.leveldeltas[0] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/button/A", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiiA).free });
OSCdef.new(\wiiB, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.leveldeltas[1] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/button/B", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiiB).free });
OSCdef.new(\wiiC, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.leveldeltas[2] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/nunchuk/button/C", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiiC).free });
OSCdef.new(\wiiZ, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.leveldeltas[3] = val.linlin(0.0,1.0,-1.0,1.0);
}, "/wii/1/nunchuk/button/Z", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiiZ).free });
OSCdef.new(\wiinunchukjoy, {
	arg msg, time, addr, ports;
	var dummy, x, y;
	# dummy, x, y = msg;
	state.levelratescale = y.linexp(0.0,1.0, 1/32, 64);
	//[\xy, x, y, state.ratescale].postln;
	}, "/wii/1/nunchuk/joy", srcID: nil, recvPort:8332);
CmdPeriod.doOnce({ OSCdef(\wiinunchukjoy).free });
OSCdef.new(\wiiright, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.gain_(state.m.gain * 17/16);
}, "/wii/1/button/Right", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiiright).free });
OSCdef.new(\wiileft, {
	arg msg, time, addr, ports;
	var path, val;
	# path, val = msg;
	state.m.gain_(state.m.gain * 16/17);
}, "/wii/1/button/Left", srcID: nil, recvPort:8332, argTemplate:[_==1]);
CmdPeriod.doOnce({ OSCdef(\wiileft).free });

//addMIDICCUpdater {|chan=0, cc=0, i=nil, mididest=nil|

//direct updaters 1: axial
t.addUpdater({|v| state.intP[0]=v}, 0); //pitch
t.addUpdater({|v| state.intP[1]=v}, 1); //pitch
t.addUpdater({|v| state.intP[2]=v}, 2); //pitch
t.addUpdater({|v| state.intP[3]=v}, 3); //pitch
t.addUpdater({|v| state.intP[4]=v}, 4); //pitch
//t.addUpdater({|v| }, 5); //???
//direct updaters 2: acceleration
t.addMIDICCUpdater(0, 6, 6);
t.addMIDICCUpdater(0, 7, 7);
//level updaters
t.addMIDICCUpdater(0, 8, 8);
t.addMIDICCUpdater(0, 9, 9);
t.addMIDICCUpdater(0, 10, 10);
t.addMIDICCUpdater(0, 11, 11);
//compound updaters
t.addMIDICCUpdater(0, 12, 12);
t.addMIDICCUpdater(0, 13, 13);
t.addMIDICCUpdater(0, 14, 14);
t.addMIDICCUpdater(0, 15, 15);
t.addMIDICCUpdater(0, 16, 16);
t.addMIDICCUpdater(0, 17, 17);
t.addMIDICCUpdater(0, 18, 18);
t.addMIDICCUpdater(0, 19, 19);
t.addMIDICCUpdater(0, 20, 20);
t.addMIDICCUpdater(0, 21, 21);
t.addMIDICCUpdater(0, 22, 22);
t.addMIDICCUpdater(0, 23, 23);
t.addMIDICCUpdater(0, 24, 24);
t.addMIDICCUpdater(0, 25, 25);
t.addMIDICCUpdater(0, 26, 26);
t.addMIDICCUpdater(0, 27, 27);
t.addMIDICCUpdater(0, 28, 28);
t.addMIDICCUpdater(0, 29, 29);
t.addMIDICCUpdater(0, 30, 30);
t.addMIDICCUpdater(0, 31, 31);
t.addMIDICCUpdater(0, 32, 32);
t.addMIDICCUpdater(0, 33, 33);
t.addMIDICCUpdater(0, 34, 34);
t.addMIDICCUpdater(0, 35, 35);
t.addMIDICCUpdater(0, 36, 36);
t.addMIDICCUpdater(0, 37, 37);
t.addMIDICCUpdater(0, 38, 38);
t.addMIDICCUpdater(0, 39, 39);
t.addMIDICCUpdater(0, 40, 40);
t.addMIDICCUpdater(0, 41, 41);
t.addMIDICCUpdater(0, 42, 42);
t.addMIDICCUpdater(0, 43, 43);
t.addMIDICCUpdater(0, 44, 44);
t.addMIDICCUpdater(0, 45, 45);
t.addMIDICCUpdater(0, 46, 46);
t.addMIDICCUpdater(0, 47, 47);
t.addMIDICCUpdater(0, 48, 48);
t.addMIDICCUpdater(0, 49, 49);
t.addMIDICCUpdater(0, 50, 50);
t.addMIDICCUpdater(0, 51, 51);
t.addMIDICCUpdater(0, 52, 52);
t.addMIDICCUpdater(0, 53, 53);
t.addMIDICCUpdater(0, 54, 54);
t.addMIDICCUpdater(0, 55, 55);
)
~s.active = ~s.active.asBoolean.not;
~s.leveldeltas;
~s.levels;

t.muteAll;
t.soloAndPing(0);
t.soloAndPing(1);
t.soloAndPing(2);
t.soloAndPing(3);
t.soloAndPing(4);
t.soloAndPing(5);
//accel
t.soloAndPing(6);
t.soloAndPing(7);
//levels
t.soloAndPing(8);
t.soloAndPing(9);
t.soloAndPing(10);
t.soloAndPing(11);
//other
t.soloAndPing(12);
t.soloAndPing(13);
t.soloAndPing(14);
t.soloAndPing(15);
t.soloAndPing(16);
t.soloAndPing(17);
t.soloAndPing(18);
t.soloAndPing(19);
t.soloAndPing(20);
t.soloAndPing(21);
t.soloAndPing(22);
t.soloAndPing(23);
t.soloAndPing(24);
t.soloAndPing(25);
t.soloAndPing(26);
t.soloAndPing(27);
t.soloAndPing(28);
t.soloAndPing(29);
t.soloAndPing(30);
t.soloAndPing(31);
t.soloAndPing(32);
t.soloAndPing(33);
t.soloAndPing(34);
t.soloAndPing(35);
t.soloAndPing(36);
t.soloAndPing(37);
t.soloAndPing(38);
t.soloAndPing(39);
t.soloAndPing(40);
t.soloAndPing(41);
t.soloAndPing(42);
t.soloAndPing(43);
t.soloAndPing(44);
t.soloAndPing(45);
t.soloAndPing(46);
t.soloAndPing(47);
t.soloAndPing(48);
t.soloAndPing(49);
t.soloAndPing(50);
t.soloAndPing(51);
t.soloAndPing(52);
t.soloAndPing(53);
t.soloAndPing(54);
t.soloAndPing(55);

t.tutti;
