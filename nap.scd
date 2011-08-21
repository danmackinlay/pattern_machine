().class

~o = Ohm64.new;
~o.src
~o.backNoteMap
~o.setNoteResponder({|...a| [\r, a].postln;}, \leftChannelButton);

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
