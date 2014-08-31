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
	//MIDIFunc.trace(true);
	MIDIFunc.trace(false);
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
	//level-on the first 4 faders
	alldefs.add(MIDIdef.cc(\vol1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicechannels[0].level_(mapped);
		[\vol1, mapped].postln;
	}, ccNum: 0, chan: 1));
	alldefs.add(MIDIdef.cc(\vol2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicechannels[1].level_(mapped);
		[\vol2, mapped].postln;
	}, ccNum: 1, chan: 1));
	alldefs.add(MIDIdef.cc(\vol3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicechannels[2].level_(mapped);
		[\vol3, mapped].postln;
	}, ccNum: 2, chan: 1));
	alldefs.add(MIDIdef.cc(\vol4, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-50.0,0.0).dbamp;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicechannels[3].level_(mapped);
		[\vol4, mapped].postln;
	}, ccNum: 3, chan: 1));

	//seed on knobs (eww)
	alldefs.add(MIDIdef.cc(\seed0, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,1,16).asInt;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicestates[0][\seed] = mapped;
		[\seed0, mapped].postln;
	}, ccNum: 16, chan: 1));
	alldefs.add(MIDIdef.cc(\seed1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,1,16).asInt;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicestates[1][\seed] = mapped;
		[\seed1, mapped].postln;
	}, ccNum: 17, chan: 1));
	alldefs.add(MIDIdef.cc(\seed2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,1,16).asInt;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicestates[2][\seed] = mapped;
		[\seed2, mapped].postln;
	}, ccNum: 18, chan: 1));
	alldefs.add(MIDIdef.cc(\seed3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,1,16).asInt;
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.voicestates[3][\seed] = mapped;
		[\seed3, mapped].postln;
	}, ccNum: 19, chan: 1));

	//loops on the buttons
	alldefs.add(MIDIdef.noteOn(\loop0, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[0][\looping] ? 0;
		state.voicestates[0][\looping] = 1-tog;
		state.loopsynths[0].set(\wet, tog);
		[\loop0, tog].postln;
	}, noteNum: 64, chan: 1));
	alldefs.add(MIDIdef.noteOn(\reseed0, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[0][\reseed] ? false;
		state.voicestates[1][\reseed] = tog.not;
		[\reseed0, tog].postln;
	}, noteNum: 48, chan: 1));
	alldefs.add(MIDIdef.noteOn(\loop1, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[1][\looping] ? 0;
		state.voicestates[1][\looping] = 1-tog;
		state.loopsynths[1].set(\wet, tog);
		[\loop1, tog].postln;
	}, noteNum: 65, chan: 1));
	alldefs.add(MIDIdef.noteOn(\reseed1, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[1][\reseed] ? false;
		state.voicestates[1][\reseed] = tog.not;
		[\reseed0, tog].postln;
	}, noteNum: 49, chan: 1));
	alldefs.add(MIDIdef.noteOn(\loop2, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[1][\looping] ? 0;
		state.voicestates[1][\looping] = 1-tog;
		state.loopsynths[1].set(\wet, tog);
		[\loop2, tog].postln;
	}, noteNum: 66, chan: 1));
	alldefs.add(MIDIdef.noteOn(\reseed2, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[0][\reseed] ? false;
		state.voicestates[1][\reseed] = tog.not;
		[\reseed2, tog].postln;
	}, noteNum: 50, chan: 1));
	alldefs.add(MIDIdef.noteOn(\loop3, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[0][\looping] ? 0;
		state.voicestates[0][\looping] = 1-tog;
		state.loopsynths[0].set(\wet, tog);
		[\loop3, tog].postln;
	}, noteNum: 67, chan: 1));
	alldefs.add(MIDIdef.noteOn(\reseed3, {|vel,pitch,chan,src|
		var tog;
		tog = state.voicestates[0][\reseed] ? false;
		state.voicestates[1][\reseed] = tog.not;
		[\reseed3, tog].postln;
	}, noteNum: 51, chan: 1));

	//input on last knobs
	alldefs.add(MIDIdef.cc(\chaos, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		state[\chaos]= mapped;
		[\chaos, mapped].postln;
	}, ccNum: 20, chan: 1));
	alldefs.add(MIDIdef.cc(\density, {|val,num,chan,src|
		var mapped = (0.5**(val.linlin(0.0,127.0,0.0,5.0).asInteger));
		state[\density]= mapped;
		[\density, mapped].postln;
	}, ccNum: 21, chan: 1));
	alldefs.add(MIDIdef.cc(\livefade, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		state.sourcesound.set(\livefade, mapped);
		[\livefade, mapped].postln;
	}, ccNum: 22, chan: 1));
	alldefs.add(MIDIdef.cc(\buffsel, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0,20).asInt;
		state.sourcesound.set(\bufnum,~sampsetbufarray[mapped]);
		[\buffsel, mapped, ~sampsetbufarray[mapped]].postln;
	}, ccNum: 23, chan: 1));

	//panic
	alldefs.add(MIDIdef.noteOn(\stop, {|vel,pitch,chan,src|
		var killAll, killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
		killAll = {[state.voices[0],state.vox2,state.vox3,state.vox4].do({|thing| thing.postln; killList.value(thing);[\killing, thing].postln;})};
	}, noteNum: 42, chan: 1));

	//metaparam on the faders
	alldefs.add(MIDIdef.cc(\meta1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparamMap.set(3, mapped);
		[\meta1, mapped].postln;
	}, ccNum: 4, chan: 1));
	alldefs.add(MIDIdef.cc(\meta2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparamMap.set(4, mapped);
		[\meta2, mapped].postln;
	}, ccNum: 5, chan: 1));
	alldefs.add(MIDIdef.cc(\meta3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparamMap.set(5, mapped);
		[\meta3, mapped].postln;
	}, ccNum: 6, chan: 1));
	alldefs.add(MIDIdef.cc(\meta4, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		//[val,num,chan,src,key, spec.map(val/127.0)].postln;
		state.metaparamMap.set(6, mapped);
		[\meta4, mapped].postln;
	}, ccNum: 7, chan: 1));

	alldefs;
};
