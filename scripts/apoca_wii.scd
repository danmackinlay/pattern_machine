{|state|
	//OSCFunc.trace(true);
	OSCdef.new(\wii, {
		arg msg, time, addr, ports;
		var dummy, pitch, roll, yaw, accel;
		# dummy, pitch, roll, yaw, accel = msg;
		//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
		state.metaparamMap.set(0, pitch, 0.0, 1.0);
		state.metaparamMap.set(1, roll, 0.0, 1.0);
		state.metaparamMap.set(2, yaw, 0.0, 1.0);
	}, "/wii/1/accel/pry", nil, 8332);
	// Have to set up disposal logic when using custom port or sclang implodes
	CmdPeriod.doOnce { OSCdef(\wii).free };
}