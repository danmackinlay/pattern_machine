{|state|
	//TODO: rate limit. ca 50Hz atm
	//OSCFunc.trace(true);
	OSCdef.new(\wii, {
		arg msg, time, addr, ports;
		var dummy, pitch, roll, yaw, accel;
		# dummy, pitch, roll, yaw, accel = msg;
		//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
		state[\pitchrollyawaccel] = [pitch, roll, yaw, accel ].asFloatArray;
		state[\metaparams][0] = pitch;
		state[\metaparams][1] = roll;
		state[\metaparams][2] = yaw;
		state.paramDirty = true;
	}, "/wii/1/accel/pry", nil, 8332);
}