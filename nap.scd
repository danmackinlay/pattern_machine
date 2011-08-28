http://www.gersic.com/blog.php?id=9

~o = Ohm64.new;
~o.initDefaultResponders;
~o.src
~o.noteMap
~o.ccMap;
~o.noteResponderMap
~o.backNoteMap

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


