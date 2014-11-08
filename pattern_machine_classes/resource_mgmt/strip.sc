//Manage my instruments in a standardised class-based way
// So that I may have comprehensible tracebacks
// and sensible scope
// and not have "nil does not understand" as my only error
// Does it make sense to attach a clock here? Generally patterns will not be aware this guy exists.
PSMasterOut {
	var <id;
	var <state;
	var <clock;
	var <proto;
	var <group;
	var <numChannels=2;
	var <bus;
	var <server;
	var <otherstuff2free;
	var <outputgainsynth;
	var <fxsynths;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
		});
	}
	//Bus is regarded as an insert, i.e. I will be playing ReplaceOut synths here
	*new {
		arg id, state, clock, group, bus, outbus, proto;
		id = id ?? {idCount = idCount + 1;};
		this.removeAt(id);
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock, proto
		).initPSMasterOut(group,bus,outbus);
	}
	*at {
		arg id;
		^all[id];
	}
	*removeAt {
		arg id;
		var prev = all.at(id);
		all.removeAt(id);
		prev.tryPerform(\free);
	}
	*newFrom {
		arg proto, id, state, clock, group, bus, outbus;
		//shorthand: copy init args from a
		proto.notNil.if({
			state.isNil.if({
				state = proto.tryPerform(\state);
			});
			clock.isNil.if({
				clock = proto.tryPerform(\clock);
			});
			group.isNil.if({
				group = proto.tryPerform(\group);
			});
			bus.isNil.if({
				bus = proto.tryPerform(\bus);
			});
		});
		^this.new(
			id, state, clock, group, bus, outbus, proto
		);
	}
	
	initPSMasterOut {
		arg gr,bs,ob;
		gr.notNil.if({
			server = gr.server;
		}, {
			server = Server.default;
		});
		all[id] = this;
		otherstuff2free = Array.new;
		server.makeBundle(nil, { // nil executes ASAP
			gr.isNil.if({
				group  = this.freeable(Group.addToTail(server)); //note default to tail here
			}, {
				group = gr;
			});
			
			bs.isNil.if({
				bus = this.freeable(Bus.audio(server,numChannels));
			},{
				bus = bs;
			});
			outputgainsynth = this.freeable(Synth.new(
				"limi__%x%".format(numChannels, numChannels),
				(
				pregain: -6.dbamp,
				out: bus,
				).getPairs,
				target: group,
				addAction: \addToTail,
			));
			
		});
	}
	free {
		otherstuff2free.do({arg stuff; stuff.free});
	}
	
	freeable {|stuff|
		otherstuff2free = otherstuff2free.add(stuff);
		^stuff;
	}
	asTarget {
		^group;
	}
	asGroup {
		^group;
	}
	asBus {
		^bus;
	}
	printOn { |stream|
		stream << this.class.asString <<"(id:" << id.asString << ")";
	}
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}

PSMasterExternalMixer {
	
}
