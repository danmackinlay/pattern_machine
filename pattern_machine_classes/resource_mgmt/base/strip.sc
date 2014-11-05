//Manage my instruments in a stanadardised class-based way
// So that I may have comprehensible tracebacks
// and sensible scope
// and no have "nil does not understand"
PSStrip {
	var <id;
	var <parent,<numChannels, <clock, <group,<bus,<inbus,<state,<server;
	var <sourcegroup, <fxgroup, <mixergroup;
	var <freebus, <freegroup;
	var <pssynths;
	var <otherstuff2free;
	var <clock;
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
			
		});
	}
	//bus is output bus
	//input can be different. How to specify?
	*new {arg id, parent, numChannels, clock, group, bus, inbus, state;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		parent.notNil.if({
			numChannels ?? {numChannels = parent.numChannels};
			state = Event.new(n:60, parent: parent.state, know: true
				).putAll(state ? ());
			clock ?? {clock = parent.clock};
			group ?? {group = parent.group};
			bus ?? {bus = parent.bus};
			inbus ?? {inbus = parent.inbus};
		});
		numChannels ?? {numChannels = 1};
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		
		^super.newCopyArgs(
			id, parent, numChannels, clock
		).initPSStrip(group,bus,state);
	}		
	initPSStrip { arg g,b,st;
		all[id] = this;
		pssynths = Array.new;
		otherstuff2free = Array.new;
		
		freegroup=false;
		
		//server=s ?? {Server.default};
		group=g ?? {freegroup=true; Group.new;};
		
		server=group.server;
		
		sourcegroup=Group.head(group);
		fxgroup=Group.tail(sourcegroup);
		mixergroup=Group.tail(fxgroup);
		
		b.isNil.if({
			//must free eventually if not passed in
			freebus=true;
			bus = Bus.audio(server,numChannels);
		},{
			freebus=false; //don't free if bus passed in code
			bus= b;
		});

		//This would be where to make a mixer, if no bus was passed in.
	}
	children {
		all.select { |strip, id| strip.parent == this };
	}
	//add one (or more) synths
	add {
		arg ...pssynths;
		pssynths.do({arg pssynth; 
			pssynth.initPSSynth(this);
			pssynths = pssynths.add(pssynth);
		});
	}
	removeAt {arg ind;
		var removed;
		removed=pssynths.removeAt(ind);
		removed.free;
	}
	free{
		pssynths.do({arg stuff; stuff.free});
		otherstuff2free.do({arg stuff; stuff.free});
		if(freebus, {
			bus.free;});
		if(freegroup, {
			group.free;});
	}
	
	freeable {|stuff|
		otherstuff2free = otherstuff2free.add(stuff);
		^stuff;
	}
	
	/*
	play {|patlike|
		var stream = patlike.play(clock: clock);
		streams2stop = streams2stop.add(pat);
	}
	*/
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}

