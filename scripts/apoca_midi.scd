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
	//level-on faders
	alldefs.add(MIDIdef.cc(\vol1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.echettechannel1.level_(mapped);
		[\vol1, mapped].postln;
	}, ccNum: 0, chan: 1));
	alldefs.add(MIDIdef.cc(\vol2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.echettechannel2.level_(mapped);
		[\vol2, mapped].postln;
	}, ccNum: 1, chan: 1));
	alldefs.add(MIDIdef.cc(\vol3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.bonuschannel1.level_(mapped);
		[\vol3, mapped].postln;
	}, ccNum: 2, chan: 1));
	alldefs.add(MIDIdef.cc(\vol4, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.bonuschannel2.level_(mapped);
		[\vol4, mapped].postln;
	}, ccNum: 3, chan: 1));

	//pan on knobs
	alldefs.add(MIDIdef.cc(\pan1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.echettechannel1.pan_(mapped);
		[\pan1, mapped].postln;
	}, ccNum: 16, chan: 1));
	alldefs.add(MIDIdef.cc(\pan2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.echettechannel2.pan_(mapped);
		[\pan2, mapped].postln;
	}, ccNum: 17, chan: 1));
	alldefs.add(MIDIdef.cc(\pan3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.bonuschannel1.pan_(mapped);
		[\pan3, mapped].postln;
	}, ccNum: 18, chan: 1));
	alldefs.add(MIDIdef.cc(\pan4, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.bonuschannel2.pan_(mapped);
		[\pan4, mapped].postln;
	}, ccNum: 19, chan: 1));

	//loops on the buttons
	alldefs.add(MIDIdef.noteOn(\loop1, {|vel,pitch,chan,src|
		var tog;
		tog = state.vox1state[\looping] ? 0;
		state.vox1state[\looping] = 1-tog;
		state.loopsynths[0].set(\wet, tog);
		[\loop1, tog].postln;
	}, noteNum: 64, chan: 1));
	alldefs.add(MIDIdef.noteOn(\reseed1, {|vel,pitch,chan,src|
		var tog;
		tog = state.vox1state[\reseed] ? false;
		state.vox1state[\reseed] = tog.not;
		[\reseed1, tog].postln;
	}, noteNum: 48, chan: 1));

	//panic
	alldefs.add(MIDIdef.noteOn(\stop, {|vel,pitch,chan,src|
		var killAll, killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
		killAll = {[state.vox1,state.vox2,state.vox3,state.vox4].do({|thing| thing.postln; killList.value(thing);[\killing, thing].postln;})};
	}, noteNum: 42, chan: 1));


	//metaparam on the faders
	alldefs.add(MIDIdef.cc(\meta1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparams[3] = mapped;
		state.paramDirty = true;
		[\meta1, mapped].postln;
	}, ccNum: 4, chan: 1));
	alldefs.add(MIDIdef.cc(\meta2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparams[4] = mapped;
		state.paramDirty = true;
		[\meta2, mapped].postln;
	}, ccNum: 5, chan: 1));
	alldefs.add(MIDIdef.cc(\meta3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparams[5] = mapped;
		state.paramDirty = true;
		[\meta3, mapped].postln;
	}, ccNum: 6, chan: 1));
	alldefs.add(MIDIdef.cc(\meta4, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparams[6] = mapped;
		state.paramDirty = true;
		[\meta4, mapped].postln;
	}, ccNum: 7, chan: 1));

	alldefs;
};
