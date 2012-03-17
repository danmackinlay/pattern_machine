/* My favourite MIDI controller, Livid Instruments' OHM64, set up just hte way I like it, with pluggable, single-button-per-responder linkages, and note-ons and note-offs handled the same way.

It also assumes that the led signal to the Ohm 

TODO:

* be bidirectional- i.e. forward note values to the device.
* handle "states" for buttons- I .e. record which should be on or off, and allow the function keys to pave between them. (this should be a separate MVC-style class)
* who knows if my Ohm64 in any way approximates factory settings? should check that.
* Who knows if this works with 2 Ohms? can't check, but I think the output stuff might be dodgy.
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
	init {|noteMappings, ccMappings|
		outPort = MIDIOut.newByName(inPort.device, inPort.name);
		this.initMaps(noteMappings, ccMappings);
		ccResponderMap = ();
		noteResponderMap = ();
		
		noteonresponder = MIDIFunc.noteOn(
			func: { |val, num, chan, src|
				var mapped = backNoteMap[num];
				//[\noteon, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, \on);
					});
				});
			}, 
			srcID: inPort.uid);
		noteoffresponder = MIDIFunc.noteOff(
			func: { |val, num, chan, src|
				var mapped = backNoteMap[num];
				//[\noteoff, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, \off);
					});
				});
			}, 
			srcID: inPort.uid);
		ccresponder = MIDIFunc.cc(
			func: { |val, num, chan, src|
				var mapped = backCCMap[num];
				//[\cc, val, num, chan, src].postln;
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  ccResponderMap[selector]  ?? { ccResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector);
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
				{|idx, val, name, onoff|
					[name, this.gridNote(idx), val, onoff].postln;},
				controlName
			);
		});
		ccMap.keysDo({|controlName|
			this.setCCResponder(
				{|idx, val, name|
					[name, idx, val].postln;},
				controlName
			);
		});
	}
	setCCResponder {|fn, key|
		/* look like {|idx, val, name|}*/
		ccResponderMap[key] = fn;
	}
	setNoteResponder {|fn, key|
		//TODO: handle default/fallback responder.
		/* look like {|idx, val, name, onoff|}*/
		noteResponderMap[key] = fn;
	}
	sendNote {|controlName, idx, val, onOff|
		var foundNote, foundControl;
		foundControl = noteMap[controlName];
		foundControl.isNil.if({("no such controlName" ++ controlName).throw;});
		foundNote = foundControl[idx];
		foundNote.isNil.if({("no such index" +idx.asString + "for control" ++ controlName).throw;});
		onOff = onOff ?? { (val>0).switch(
			true, \on,
			false, \off
		)};
		(onOff === \on).if(
			{outPort.noteOn(0,foundNote,val);},
			{outPort.noteOff(0,foundNote,val);}
		);
	}
}