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
			//I call this magic incantation "the Nausicaa spell", because it causes
			// SC to listen to the Ohm
			var inPorts = 16;
			var outPorts = 16;
			// explicitly initialize the client for more MIDI ports than we are
			// likely to need, or it doesn't show up.
			MIDIClient.init(inPorts,outPorts);
			inPorts.do({ arg i; 
				MIDIIn.connect(i, MIDIClient.sources.at(i));
			});
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
	init {|noteMappings, ccMappings|
		outPort = MIDIOut.newByName(inPort.device, inPort.name);
		this.initMaps(noteMappings, ccMappings);
		ccResponderMap = ();
		noteResponderMap = ();
		
		//These responders could probably be set up in a more efficient way by
		// creating one responder per mapped note. But much more complex to do so.
		// Pfft. Or this could all be refactored into a less duplicated function.
		noteonresponder = NoteOnResponder(
			{ |x, xx, num, val|
				var mapped = backNoteMap[num];
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, \on);
					});
				});
			}, 
			inPort);
		noteoffresponder = NoteOffResponder(
			{ |x, xx, num, val|
				var mapped = backNoteMap[num];
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  noteResponderMap[selector]  ?? { noteResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector, \off);
					});
				});
			}, 
			inPort);
		ccresponder = CCResponder(
			{ |x, xx, num, val|
				var mapped = backCCMap[num];
				mapped.notNil.if({
					var selector, id, responder;
					# selector, id = mapped;
					responder =  ccResponderMap[selector]  ?? { ccResponderMap[\_default]};
					responder.notNil.if({
						responder.value(id, val, selector);
					});
				});
			}, 
			inPort);
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
	initDefaultResponders {
		noteMap.keysDo({|controlName|
			this.setNoteResponder(
				{|...a| [controlName, a].postln;},
				controlName
			);
		});
		ccMap.keysDo({|controlName|
			this.setCCResponder(
				{|...a| [controlName, a].postln;},
				controlName
			);
		});
	}
	setCCResponder {|fn, key|
		ccResponderMap[key] = fn;
	}
	setNoteResponder {|fn, key|
		//TODO: handle default/fallback responder.
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