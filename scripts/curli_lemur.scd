{|state|
	var alldefs;
	alldefs = List.new;
	OSCFunc.new({}, '/fader8/out', nil, 12000);
	OSCFunc.trace(true);
	OSCFunc.trace(false);
	//s.dumpOSC(1);
	//s.dumpOSC(0);
	alldefs;
};
