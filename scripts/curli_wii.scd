{|state|
	//OSCFunc.trace(true);
	OSCdef.new(\wiipry, {
		arg msg, time, addr, ports;
		var dummy, pitch, roll, yaw, accel;
		# dummy, pitch, roll, yaw, accel = msg;
		//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
		state.metaparamMap.set(0, pitch, 0.0, 1.0);
		state.metaparamMap.set(1, roll, 0.0, 1.0);
		state.metaparamMap.set(2, yaw, 0.0, 1.0);
	}, "/wii/1/accel/pry", nil, 8332);
	// Have to set up disposal logic when using custom port or sclang implodes
	CmdPeriod.doOnce { OSCdef(\wiipry).free };
	OSCdef.new(\wiiplus, {
		arg msg, time, addr, ports;
		var path, val;
		# path, val = msg;
		state.metaparamMap.phi_(state.metaparamMap.phi + 0.001953125);
	}, "/wii/1/button/Plus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
	CmdPeriod.doOnce { OSCdef(\wiiplus).free };
	OSCdef.new(\wiiminus, {
		arg msg, time, addr, ports;
		var path, val;
		# path, val = msg;
		state.metaparamMap.phi_(state.metaparamMap.phi - 0.001953125);
	}, "/wii/1/button/Minus", srcID: nil, recvPort:8332, argTemplate:[_==1]);
	CmdPeriod.doOnce { OSCdef(\wiiminus).free };
}