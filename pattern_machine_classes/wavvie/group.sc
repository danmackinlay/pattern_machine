//Manage a whole bunch of sequencing for my typical synth voice. 
PSWavvieStrip {
	var <parent,<numChannels, <clock, <group,<bus,<state,<index,<server;
	var <synthgroup, <fxgroup, <mixergroup;
	var <freebus, <freegroup;
	var <streams2stop, <stuff2free;
	var <clock;
	 
	*new {arg parent, numChannels, clock, group, bus, state;
		parent.notNil.if({
			numChannels ?? {numChannels = parent.numChannels};
			state = Event.new(n:60, proto: parent.state, know: true
				).putAll(state);
			clock ?? {clock = parent.clock};
			group ?? {group = parent.group};
			bus ?? {bus = parent.bus};
		});
		numChannels ?? {numChannels = 1};
		state ?? {state = Event.new(n:60, know: true
			).putAll(state)};
		clock ?? {clock = TempoClock.default};
		
		^super.newCopyArgs(
			parent, numChannels, clock
		).initWavvieStrip(group,bus,state);
	}	
	
	initWavvieStrip { arg g,b,st;
		streams2stop = Array.new;
		stuff2free = Array.new;
		
		freegroup=false;
		
		//server=s ?? {Server.default};
		group=g ?? {freegroup=true; Group.new;};
		
		server=group.server;
		
		synthgroup=Group.head(group);
		fxgroup=Group.after(synthgroup);
		mixergroup=Group.after(fxgroup);
				
		freebus=false; //don't free if bus passed in, responsibility of client code
		bus= b ?? {
			//must free eventually if not passed in
			freebus=true;
			Bus.audio(server,numChannels);
		};//{Bus.new(\audio,0,numChannels,server)}; //defaults  
		index=bus.index;
		
		this.initFX;
		this.initSources;
		
		//This would be where to make a mixer, if no bus was passed in.
	}
	
	initFX {}
	
	initSources {}
	
	free {
		streams2stop.do({arg pat; pat.stop});
		stuff2free.do({arg stuff; stuff.free});
				
		if(freebus, {
			bus.free;});
		
		if(freegroup, {
			group.free;});
	}
	
	play {|pat|
		var stream = 
		streams2stop = streams2stop.add(pat);
	}
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
	
	addFreeable {|stuff|
		stuff2free = stuff2free.add(stuff);
		^stuff;
	}
	
}
