//Manage my instruments in a stanadardised class-based way
// So that I may have comprehensible tracebacks
// and sensible scope
// and not have "nil does not understand" as my only error
// Does this work atm?
PSSamplingStrip {
	var <id;
	var <parent, <numChannels, <clock, <group;
	var <bus, <inbus, <phasebus, <state;
	var <samples;
	var <server;
	var <buffer;
	var <sourcegroup, <fxgroup, <mixergroup;
	var <otherstuff2free;
	var <recsynth, <inputgainsynth, <sourcesoundsynth;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
		});
	}
	//bus is output bus
	*new {
		arg id, parent, numChannels, clock, group, bus, inbus, phasebus, state, samples;
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
		).initPSSamplingStrip(group,bus,inbus,phasebus,state, samples);
	}
	initPSSamplingStrip {
		arg g,b,ib,pb, st, samps;
		all[id] = this;
		otherstuff2free = Array.new;
		
		g.isNil.if({
			group  = this.freeable(Group.new);
		}, {
			group = g;
		});
		
		server=group.server;
		
		sourcegroup=Group.head(group);
		fxgroup=Group.tail(sourcegroup);
		mixergroup=Group.tail(fxgroup);
		
		b.isNil.if({
			bus = this.freeable(Bus.audio(server,numChannels));
		},{
			bus= b;
		});
		
		pb.isNil.if({
			phasebus = this.freeable(Bus.control(server, 1));
		}, {
			phasebus = pb;
		});

		ib.isNil.if({
			inbus = this.freeable(Bus.control(server, 1));
		}, {
			inbus = ib;
		});
		
		recsynth = this.freeable((
			instrument: \ps_bufwr_resumable__1x1,
			in: bus,
			bufnum: buffer,
			phasebus: phasebus,
			fadetime: 0.05,
			group: sourcegroup,
			addAction: \addToTail
			sendGate: false,//persist
		).postcs.play);
		otherstuff2free = otherstuff2free.add(recsynth);
		inputgainsynth = this.freeable((
			instrument: \limi__1x1,
			pregain: 10.dbamp,
			out: bus,
			group: sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).postcs.play);
		sourcesoundsynth = this.freeable((
			instrument: \bufrd_or_live__1x1,
			looptime: this.beat2sec(16),
			offset: 0.0,
			in: inbus,
			out: bus,
			group: inputgainsynth,
			addAction: \addBefore,
			bufnum: samples.default,
			livefade: 0.0,
			loop: 1,
			sendGate: false,//persist
		).postcs.play);
		//This would be where to make a mixer, if no bus was passed in.
	}
	rec {|dur=10.0|
		recsynth.set(\t_rec, dur);
	}
	children {
		all.select { |strip, id| strip.parent == this };
	}
	free {
		otherstuff2free.do({arg stuff; stuff.free});
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

//Giggin' master group
PSMasterInternalMixer {
	
}
PSMasterExternalMixer {
	
}
/*
~limiter = (
	instrument: \limi__2x2,
	out: ~masteroutbus,
	group: strip.mixergroup,
	server: ~server,
	addAction: \addToTail,
	sendGate: false,//persist
).play;
CmdPeriod.doOnce({ state.limiter.free });

~listeners = ~instbuses.collect({|bus| (
	instrument: \jack__2,
	in: bus,
	out: ~masteroutbus,
	group: strip.mixergroup,
	server: ~server,
	addAction: \addToHead,
	sendGate: false,//persist
).play;});
*/
