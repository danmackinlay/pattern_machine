/* My favourite MIDI controller, Livid Instruments' OHM64, set up just hte way I like it, with pluggable, single-button-per-responder linkages, and note-ons and note-offs handled the same way.

It also assumes that the led signal to the Ohm 

TODO:

* be bidirectional- i.e. forward note values to the device.
* handle "states" for buttons- I .e. record which should be on or off, and allow the function keys to pave between them. (this should be a separate MVC-style class)
* who knows if my Ohm64 in any way approximates factory settings? should check that.
* Who knows if this works with 2 Ohms? can't check, but I think the output stuff might be dodgy.

Example usage:

~o=Ohm64.new;
~o.initDebugResponders;
~o.outPort.uid;
~o.inPort.uid;
~o.chan;
~o.degridNote([2,3]);
~o.sendGridNote([2,4],1);
~o.sendGridNote([2,4],0);
*/

Ohm64 {
	var <inPort;
	var <outPort;
	var <ccresponder;
	var <noteonresponder;
	var <noteoffresponder;
	var <ccMap;
	var <noteMap;
	var <backCCMap;
	var <backNoteMap;
	var <ccResponderMap;
	var <noteResponderMap;
	var <chan=0; //assumed the same throughout, updated automagically if not 0
	
	*new {|inPort|
		inPort = inPort ?? {
			MIDIIn.connectAll;
			MIDIIn.findPort("Ohm64", "Control Surface");
		};
		("Ohm64 listening on" ++ inPort.asString).postln;
		^super.newCopyArgs(inPort).init(this.noteMappings, this.ccMappings);
	}
	*noteMappings {
		//override this to define different notegroups
		var noteMap = ();
		noteMap.leftChannelButton = [65, 73, 66, 74];
		noteMap.rightChannelButton = [67, 75, 68, 76];
		noteMap.leftButton = [64];
		noteMap.rightButton = [72];
		noteMap.fButton = [77, 78, 79, 69, 70, 71];
		noteMap.magicButton = [87];
		//wacky. this makes the button labels line up with note #.
		noteMap.grid = Array.iota(8,8).flop.flatten;
		^noteMap;
	}
	*ccMappings {
		var ccMap = ();
		ccMap.leftFaders = [23, 22, 15, 14];
		ccMap.rightFaders = [5, 7, 6, 4];
		ccMap.leftKnobs = [21, 20, 13, 12, 19, 18, 11, 10, 17, 16, 9, 8];
		ccMap.rightKnobs = [3, 1, 0, 2];
		ccMap.xFader = [24];
		^ccMap;
	}
	gridNote {|idx|
		//divmod turns the Note number into a grid ref.
		var row = (idx/8).floor;
		^[row, idx-(8*row)];
	}
	degridNote {|rowcol|
		^(rowcol[0]*8) + (rowcol[1]);
	}
	init {|noteMappings, ccMappings|
		outPort = MIDIOut.newByName(inPort.device, inPort.name);
		this.initMaps(noteMappings, ccMappings);
		ccResponderMap = ();
		noteResponderMap = ();
		
		noteonresponder = MIDIFunc.noteOn(
			func: { |val, num, inchan, src|
				var mapped = backNoteMap[num];
				chan = inchan;
				//[\noteon, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, inchan, true);
					});
				});
			}, 
			srcID: inPort.uid);
		noteoffresponder = MIDIFunc.noteOff(
			func: { |val, num, inchan, src|
				var mapped = backNoteMap[num];
				chan = inchan;
				//[\noteoff, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, inchan, false);
					});
				});
			}, 
			srcID: inPort.uid);
		ccresponder = MIDIFunc.cc(
			func: { |val, num, inchan, src|
				var mapped = backCCMap[num];
				chan = inchan;
				//[\cc, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  ccResponderMap[selector]  ?? { ccResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, inchan);
					});
				});
			}, 
			srcID: inPort.uid);
	}
	initMaps {|noteMappings, ccMappings|
		noteMap = noteMappings;
		ccMap = ccMappings;
		backNoteMap = ();
		backCCMap = ();
		noteMap.keysValuesDo({|key, ids|
			ids.do({|midiId, localId|
				backNoteMap[midiId] = [key, localId];
			});
		});
		ccMap.keysValuesDo({|key, ids|
			ids.do({|midiId, localId|
				backCCMap[midiId] = [key, localId];
			});
		});
	}
	initDebugResponders {
		noteMap.keysDo({|controlName|
			this.setNoteResponder(
				controlName,
				{|idx, val, name, chan, on|
					[name, this.gridNote(idx), val, chan, on].postln;}
			);
		});
		ccMap.keysDo({|controlName|
			this.setCCResponder(
				controlName,
				{|idx, val, name, chan|
					[name, idx, val, chan].postln;}
			);
		});
	}
	setCCResponder {|controlName, fn|
		/* look like {|idx, val, name, chan|}*/
		ccResponderMap[controlName] = fn;
	}
	setNoteResponder {|controlName, fn|
		//TODO: handle default/fallback responder.
		/* look like {|idx, val, name, chan, on|}*/
		noteResponderMap[controlName] = fn;
	}
	sendNote {|idx, val, outchan, on, controlName|
		var foundNote, foundControl;
		outchan = outchan ? chan;
		foundControl = noteMap[controlName];
		foundControl.isNil.if({("no such controlName" + controlName).throw;});
		foundNote = foundControl[idx];
		foundNote.isNil.if({("no such index" +idx.asString + "for control" ++ controlName).throw;});
		on = on ? (val>0);
		on.if(
			{outPort.noteOn(outchan,foundNote,val); [\noteonout, outchan, foundNote, val].postln;},
			{outPort.noteOff(outchan,foundNote,val); [\noteoffout, outchan, foundNote, val].postln;}
		);
	}
	resetLights{
		noteMap.keysValuesDo({|controlName, ids|
			ids.do({|midiId, localId|
				this.sendNote(idx:localId, val:0, on:false, controlName:controlName);
			});
		});
		
	}
	sendGridNote {|rowcol, val, outchan, on, controlName=\grid|
		this.sendNote(this.degridNote(rowcol), val, outchan, on, controlName);
	}
}