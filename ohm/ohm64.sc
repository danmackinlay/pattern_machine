Ohm64 {
	var <src;
	var <ccresponder;
	var <noteonresponder;
	var <noteoffresponder;
	var <ccMap;
	var <noteMap;
	var <backCCMap;
	var <backNoteMap;
	var <ccResponderMap;
	var <noteResponderMap;
	
	*new {|src|
		src = src ?? {
			//this magic incantation causes SC to listen to the Ohm
			var inPorts = 16;
			var outPorts = 16;
			MIDIClient.init(inPorts,outPorts);			// explicitly intialize the client
			inPorts.do({ arg i; 
				MIDIIn.connect(i, MIDIClient.sources.at(i));
			});
			MIDIIn.findPort("Ohm64", "Control Surface");
		};
		^super.newCopyArgs(src).init(this.noteMappings, this.ccMappings);
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
		ccMap.rightButton = [72];
		ccMap.fButton = [77, 78, 79, 69, 70, 71];
		^ccMap;
	}
	init {|noteMappings, ccMappings|
		this.initMaps(noteMappings, ccMappings);
		ccResponderMap = ();
		noteResponderMap = ();
		
		noteonresponder = NoteOnResponder(
			{ |x, xx, num, val|
				var mapped = backNoteMap[num];
				mapped.isNil.not.if({
					var selector, id;
					# selector, id = mapped;
					noteResponderMap[selector].isNil.not.if({
							noteResponderMap[selector].value(id, val);
						}, {("unknown control " ++ selector).postln;}
					);
				}, {("unknown note " ++ num).postln;});
			}, 
			src);
		noteoffresponder = NoteOffResponder(
			{ |x, xx, num, val|
				[\noteoff, x, xx, num, val].postln;
			}, 
			src);
		ccresponder= CCResponder(
			{|x, xx, num, val|
				[\cc, x, xx, num, val].postln;
			},
			src);
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
				backNoteMap[midiId] = [key, localId];
			});
		});
	}
	setCCResponder {|fn, key|
		ccResponderMap[key] = fn;
	}
	setNoteResponder {|fn, key|
		noteResponderMap[key] = fn;
	}
	
}