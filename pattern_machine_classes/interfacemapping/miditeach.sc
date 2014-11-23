/*
MIDIClient.init;
MIDIClient.destinations;
~miditeacher = MidiTeacher(
    MIDIOut.newByName("IAC-Driver", "Bus 1"),
   [[5,0], [5,1], [5,2], [5,3], [5,4]]
);
*/
MidiTeacher {
	var <>midiout;
	var <chanControls;
	var <currIdx = 0;
	var <window;
	var <txt;
	
	*new {|midiout, chanControls, currIdx=0|
		chanControls = chanControls ? [[0,0],[0,1],[0,5]];
		midiout = midiout ?? {MIDIOut.newByName("IAC-Driver", "Bus 1")};
		midiout.connect;
		^super.newCopyArgs(midiout, chanControls, currIdx).initMidiTeacher;
	}
	initMidiTeacher {
		{this.makeGUI;}.defer;
		this.setIdx;
	}
	makeGUI {
		window = Window.new("MIDI teach", Rect(200,200,255,100));
		txt = StaticText.new(
			window, Rect(0,0,255,100)
		).string_("- - -"
		).align_(\center
		).font_(Font("Arial", 40.0, true, true, true));
		window.view.keyUpAction = {|view, char, modifiers, unicode, keycode, key|
			//[view, char, modifiers, unicode, keycode, key].postln;
			(
				16777234: {this.dec.value;},
				16777236: {this.inc.value;},
				32: {this.ping.value;},
			)[key].value;
		};
		window.front;
	}
	dec {this.setIdx(currIdx-1);}
	inc {this.setIdx(currIdx+1);}
	setIdx {|val|
		var chan, cc, idx = (val ? currIdx) % (chanControls.size);
		currIdx = idx;
		# chan, cc = chanControls[idx];
		txt.string_("% % %".format(idx , chan, cc));
	}
	ping  {
		var chan, cc;
		# chan, cc = chanControls[currIdx];
		//[\pinging, chan, cc].postln;
		midiout.control (chan:chan, ctlNum: cc, val: 64);
		midiout.control (chan:chan, ctlNum: cc, val: 65);
	}
}
