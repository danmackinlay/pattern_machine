{|state|
	var sliderMeta, stateMeta, sliderInPort, buttonMeta, alldefs;
	[\mapcontroller, state].postcs;
	alldefs = List.new;
	sliderInPort = state.sliderInPort ?? {
		MIDIClient.init;
		MIDIClient.list;
		MIDIIn.connectAll;
		// MIDIIn.findPort("nanoKEY2", "CTRL")
		//state.sliderInPort = MIDIIn.findPort("nanoKONTROL2", "CTRL");
		state.sliderInPort;
	};
	MIDIFunc.trace(true);
	sliderMeta =[
		[1,  0],//slider 1
		[1, 16],//knob 1
		[1,  1],//slider 2
		[1, 17],//knob 2
		[1,  2],//etc
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
	alldefs.add(MIDIdef.cc(\vol1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.echettechannel1.level_(mapped);
		[\vol1, mapped].postln;
	}, ccNum: 0, chan: 1));
	alldefs;
};
