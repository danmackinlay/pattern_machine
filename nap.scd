http://www.gersic.com/blog.php?id=9

~o = Ohm64.new;
~o.inPort.device;
~o.outPort.port;
~o.initDefaultResponders;
~o.sendNote(\grid, 0, 64, \on);
~o.sendNote(\grid, 0, 0, \off);
~o.sendNote(\grid, 0, 0);

~o.src
~o.noteMap
~o.ccMap;
~o.noteResponderMap
~o.backNoteMap


MIDIClient.destinations
~o.setNoteResponder({|...a| [\l, a].postln;}, \leftChannelButton);
~o.setNoteResponder({|...a| [\g, a].postln;}, \grid);

MIDIResponder.removeAll;

NoteOffResponder

(
c = NoteOnResponder({ |src,chan,note,vel|
	[src,chan,note,vel].postln;
	},
	nil, // any source
	nil, // any channel
	nil, // any note
	nil // any vel
)
)
(
c = CCResponder({ |src,chan,note,vel|
	[src,chan,note,vel].postln;
	},
	nil, // any source
	nil, // any channel
	nil, // any note
	nil // any vel
)
)


