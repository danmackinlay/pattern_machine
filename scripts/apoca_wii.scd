{|uidata, callback|
	//TODO: rate limit. ca 50Hz atm
	//OSCFunc.trace(true);
	OSCdef.new(\wii, {
		arg msg, time, addr, ports;
		var dummy, pitch, roll, yaw, accel;
		# dummy, pitch, roll, yaw, accel = msg;
		//[\pitchrollyawaccel,pitch, roll, yaw, accel].postln;
		uidata[\pitchrollyawaccel] = [pitch, roll, yaw, accel ];
		callback.value(\pitchrollyawaccel);
	}, "/wii/1/accel/pry", nil, 8332);
}