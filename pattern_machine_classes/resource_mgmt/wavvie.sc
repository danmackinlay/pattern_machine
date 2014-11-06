//A particular sampling doohickey
PSWavvie {
	var <id;
	var <state;
	var <clock;
	var <proto;
	var <group;
	var <headgroup, <midgroup, <tailgroup;
	var <numChannels=2;
	var <bus, <inbus, <outbus;
	var <server;
	var <otherstuff2free;
	var <recstrip, <playstrip;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
		});
	}
	//inbus and outbus presumed shared. other mangling happens within.
	*new {
		arg id, state, clock, group, bus, inbus, outbus, samples, proto;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock, proto
		).initPSWavvie(group,bus,inbus,samples);
	}
	*newFrom {
		arg proto, id, state, clock, group, bus, inbus, outbus, samples;
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
			//Don't ever claim the private bus
			/*bus.isNil.if({
				bus = proto.tryPerform(\bus);
			});*/
			inbus.isNil.if({
				inbus = proto.tryPerform(\inbus);
			});
			outbus.isNil.if({
				outbus = proto.tryPerform(\outbus);
			});
			samples.isNil.if({
				samples = proto.tryPerform(\samples);
			});
		});
		^this.new(
			id:id,
			state:state,
			clock:clock,
			group:group,
			bus:bus,
			inbus:inbus,
			outbus:outbus,
			samples:samples,
			proto: proto
		);
	}
	
	initPSWavvie {
		arg gr,bs,ib,samps;
		gr.notNil.if({
			server = gr.server;
		}, {
			server = Server.default;
		});
		all[id] = this;
		otherstuff2free = Array.new;
		{
			server.makeBundle(0.0, {
				gr.isNil.if({
					group  = this.freeable(Group.new(server));
				}, {
					group = gr;
				});
				headgroup = this.freeable(Group.head(group));
				midgroup = this.freeable(Group.after(headgroup));
				tailgroup = this.freeable(Group.tail(group));
				bs.isNil.if({
					bus = this.freeable(Bus.audio(server,numChannels));
				},{
					bus = bs;
				});
			
				ib.isNil.if({
					inbus = this.freeable(Bus.audio(server, numChannels));
				}, {
					inbus = ib;
				});
			});
			server.sync;
			recstrip = this.freeable(
				PSSamplingStrip.newFrom(proto: this, group: headgroup)
			);
			playstrip = this.freeable(
				PSStrip.newFrom(proto: this, group: tailgroup)
			);
		}.forkIfNeeded;
	}
	free {
		otherstuff2free.do({arg stuff; stuff.free});
	}
	
	freeable {|stuff|
		otherstuff2free = otherstuff2free.add(stuff);
		^stuff;
	}
	
	baseEvent {
		^state.putAll((
			out: bus,
			group: midgroup,
			now: recstrip.phasebus.asMap,
			bufnum: recstrip.buf,
			addAction: \addToTail, 
		));
	}
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}
