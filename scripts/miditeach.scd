MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut.newByName("IAC Driver", "IAC Bus 1");
(
var mapper = (
	chanControls: [[0,0],[0,1],[0,2]],
	currIdx: 0,
);
mapper.window = Window.new("MIDI teach", Rect(200,200,255,100));
mapper.txt = StaticText.new(
	mapper.window, Rect(0,0,255,100)
).string_("Hello"
).align_(\center
).font_("Arial", 40, true
);
mapper.dec = {mapper[\setIdx].value(mapper[\currIdx]-1)};
mapper.inc = {mapper[\setIdx].value(mapper[\currIdx]+1)};
mapper.setIdx = {|val,otherval|
	mapper.currIdx = val % (mapper.chanControls.size);

};
mapper.ping = {
//pass
};
mapper.window.view.keyUpAction = {|view, char, modifiers, unicode, keycode, key|
	//[view, char, modifiers, unicode, keycode, key].postln;
	(
		16777234: {mapper.dec.value;},
		16777236: {mapper.inc.value;},
		32: {mapper.ping.value;},
	)[key].value;
};
mapper.window.front;
~mapper = mapper;
)
~mapper.currIdx;
~mapper.chanControls;