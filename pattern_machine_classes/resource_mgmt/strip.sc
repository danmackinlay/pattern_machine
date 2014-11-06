//Manage my instruments in a stanadardised class-based way
// So that I may have comprehensible tracebacks
// and sensible scope
// and not have "nil does not understand" as my only error
// Does this work atm?
PSSamplingStrip {
	var <id;
	var <state;
	var <clock;
	var <proto;
	var <group;
	var <numChannels=1; //later I can do stereo.
	var <inbus, <bus, <phasebus;
	var <buf;
	var <samples;
	var <server;
	var <buffer;
	var <otherstuff2free;
	var <jacksynth, <recsynth, <inputgainsynth, <sourcesoundsynth;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
		});
	}
	//bus is private bus for general mangling. inbus presumed shared.
	*new {
		arg id, state, clock, group, bus, inbus, phasebus, buf, samples, proto;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock, proto
		).initPSSamplingStrip(group,bus,inbus,phasebus,buf,samples);
	}
	*newFrom {
		arg proto, id, state, clock, group, bus, inbus, phasebus, buf, samples;
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
			inbus.isNil.if({
				inbus = proto.tryPerform(\inbus);
			});
			phasebus.isNil.if({
				phasebus = proto.tryPerform(\phasebus);
			});
			buf.isNil.if({
				buf = proto.tryPerform(\buf);
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
			phasebus:phasebus,
			buf:buf,
			samples:samples,
			proto:proto
		);
	}
	
	initPSSamplingStrip {
		arg gr,bs,ib,pb,bf,samps;
		gr.notNil.if({
			server = gr.server;
		}, {
			server = Server.default;
		});
		all[id] = this;
		otherstuff2free = Array.new;		
		server.makeBundle(0.0, { // nil executes ASAP
			gr.isNil.if({
				group  = this.freeable(Group.new(server));
			}, {
				group = gr;
			});
			
			bs.isNil.if({
				bus = this.freeable(Bus.audio(server,numChannels));
			},{
				bus = bs;
			});
		
			pb.isNil.if({
				phasebus = this.freeable(Bus.control(server, 1));
			}, {
				phasebus = pb;
			});

			ib.isNil.if({
				inbus = this.freeable(Bus.audio(server, numChannels));
			}, {
				inbus = ib;
			});
			bf.isNil.if({
				buf  = this.freeable(
					Buffer.new(server, server.sampleRate * 60.0)
				);
			}, {
				buf = bf;
			});
			jacksynth = this.freeable(Synth.new(
				"jack__%".format(numChannels),
				(
				in: inbus,
				out: bus,
				).getPairs,
				target: group,
				addAction: \addToHead,
			));
			//['jacksynth', jacksynth].postcs;
			inputgainsynth = this.freeable(Synth.new(
				"limi__%x%".format(numChannels, numChannels),
				(
				pregain: 10.dbamp,
				out: bus,
				).getPairs,
				target: jacksynth,
				addAction: \addAfter,
			));
			//['inputgainsynth', inputgainsynth].postcs;
			samples.notNil.if({
				sourcesoundsynth = this.freeable(Synth.new(
					"bufrd_or_live__%x%".format(numChannels, numChannels),
					(
					looptime: this.beat2sec(16),
					offset: 0.0,
					in: inbus,
					out: bus,
					bufnum: samples.at(0),
					livefade: 0.0,
					loop: 1,
					).getPairs,
					target: inputgainsynth,
					addAction: \addAfter,
				));
				//['sourcesoundsynth', sourcesoundsynth].postcs;
			});
			recsynth = this.freeable(Synth.new(
				"ps_bufwr_resumable__%x%".format(numChannels, numChannels),
				(
				in: bus,
				bufnum: buffer,
				phasebus: phasebus,
				fadetime: 0.05,
				).getPairs,
				target: group,
				addAction: \addToTail,
			));
			//['recsynth', recsynth].postcs;
		});
	}
	rec {|dur=10.0|
		recsynth.set(\t_rec, dur);
	}
	free {
		otherstuff2free.do({arg stuff; stuff.free});
	}
	
	freeable {|stuff|
		otherstuff2free = otherstuff2free.add(stuff);
		^stuff;
	}
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}

PSStrip {
	var <id;
	var <state;
	var <clock;
	var <proto;
	var <group;
	var <numChannels=2;
	var <bus, <outbus;
	var <server;
	var <otherstuff2free;
	var <jacksynth;
	var <fxsynths;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			//this.loadSynthDefs;
			all = IdentityDictionary.new;
		});
	}
	//bus is private bus for general mangling. outbus presumed shared.
	*new {
		arg id, state, clock, group, bus, outbus, proto;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock, proto
		).initPSStrip(group,bus,outbus);
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
			outbus.isNil.if({
				outbus = proto.tryPerform(\outbus);
			});
		});
		^this.new(
			id:id,
			state:state,
			clock:clock,
			group:group,
			bus:bus,
			outbus:outbus,
			proto:proto
		);
	}
	
	initPSStrip {
		arg gr,bs,ob;
		gr.notNil.if({
			server = gr.server;
		}, {
			server = Server.default;
		});
		all[id] = this;
		otherstuff2free = Array.new;		
		server.makeBundle(0.0, { // nil executes ASAP
			gr.isNil.if({
				group  = this.freeable(Group.new(server));
			}, {
				group = gr;
			});
			
			bs.isNil.if({
				bus = this.freeable(Bus.audio(server,numChannels));
			},{
				bus = bs;
			});
			
			ob.isNil.if({
				outbus = this.freeable(Bus.audio(server, numChannels));
			}, {
				outbus = ob;
			});

			jacksynth = this.freeable(Synth.new(
				"jack__%".format(numChannels),
				(
					in: bus,
					out: outbus,
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
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}

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
	//Bus is regarded as an insert
	*new {
		arg id, state, clock, group, bus, outbus, proto;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock, proto
		).initPSMasterOut(group,bus,outbus);
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
		server.makeBundle(0.0, { // nil executes ASAP
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
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}

PSMasterExternalMixer {
	
}
