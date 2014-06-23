(
var mapper;
MIDIClient.init;
//MIDIClient.destinations;
mapper = (
	chanControls: [[0,0],[0,1],[0,5]],
	currIdx: 0,
);
mapper.midiout = MIDIOut.newByName("IAC-Driver", "Bus 1");
mapper.midiout.connect;
mapper.window = Window.new("MIDI teach", Rect(200,200,255,100));
mapper.txt = StaticText.new(
	mapper.window, Rect(0,0,255,100)
).string_("Hello"
).align_(\center
).font_(Font("Arial", 40.0, true, true, true)
);
mapper.dec = {mapper[\setIdx].value(mapper[\currIdx]-1)};
mapper.inc = {mapper[\setIdx].value(mapper[\currIdx]+1)};
mapper.setIdx = {|val|
	var chan, cc, idx = val % (mapper.chanControls.size);
	mapper.currIdx = idx;
	# chan, cc = mapper.chanControls[idx];
	mapper.txt.string_("% % %".format(idx , chan, cc));
};
mapper.ping = {
	var chan, cc;
	# chan, cc = mapper.chanControls[mapper.currIdx];
	mapper.midiout.control (chan, ctlNum: cc, val: 64);
	mapper.midiout.control (chan, ctlNum: cc, val: 65);
};
mapper.window.view.keyUpAction = {|view, char, modifiers, unicode, keycode, key|
	//[view, char, modifiers, unicode, keycode, key].postln;
	(
		16777234: {mapper.dec.value;},
		16777236: {mapper.inc.value;},
		32: {mapper.ping.value;},
	)[key].value;
};
mapper[\setIdx].value(0);
mapper.window.front;
~mapper = mapper;
)
