var mapController = {|state|
	var sliderMeta, stateMeta, sliderInPort;
	sliderInPort = state.sliderInPort ?? {
		MIDIClient.init;
		MIDIClient.list;
		MIDIIn.connectAll;
		// MIDIIn.findPort("nanoKEY2", "CTRL")
		//state.sliderInPort = MIDIIn.findPort("nanoKONTROL2", "CTRL");
		state.sliderInPort;
	};
	MIDIFunc.trace(false);
	sliderMeta =[
		[1,  0],
		[1, 16],
		[1,  1],
		[1, 17],
		[1,  2],
		[1, 18],
		[1,  3],
		[1, 19],
		[1,  4],
		[1, 20],
		[1,  5],
		[1, 21],
		[1,  6],
		[1, 22],
		[1,  7],
		[1, 23],
	];
	stateMeta =  [
		\meanDb, [-50.0,0.0].asSpec,
		\dbRange, [0.0,20.0].asSpec,
		\meanPos, [-1.0,1.0].asSpec,
		\posRange, [0.0,1.0].asSpec,
		\meanDist, [0.0,3.0].asSpec,
		\distRange, [0.0,1.0].asSpec,
		\density, [0.0,2.0].asSpec,
		\timeShuffleRange, [0.0,8.0].asSpec,
	];
	stateMeta.pairsDo({|key, spec, i|
		var chan, num;
		# chan, num = sliderMeta[i/2];
		MIDIFunc.cc({|val,num,chan,src|
			//[val,num,chan,src,key, spec.map(val/127.0)].postln;
			state[key] = spec.map(val/127.0);
			//state.asCompileString.postln;
		}, ccNum: num, chan: chan);
	});
};
mapController;