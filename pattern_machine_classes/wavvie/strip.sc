//Manage my instruments in a stanadardised class-based way
// So that I may have comprehensible tracebacks
// and sensible scope
// and not have "nil does not understand" as my only error
// Does this work atm?
PSSamplingStrip {
	var <id;
	var <state;
	var <clock;
	var <group;
	var <numChannels=1; //later I can do stereo.
	var <inbus, <bus, <phasebus;
	var <buf;
	var <samples;
	var <server;
	var <buffer;
	var <sourcegroup, <fxgroup, <mixergroup;
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
		arg id, state, clock, group, bus, inbus, phasebus, buf, samples;
		id = id ?? {idCount = idCount + 1;};
		all[id].notNil.if({
			^all[id];
		});
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		[\AAA].postcs;
		^super.newCopyArgs(
			id, state, clock
		).initPSSamplingStrip(group,bus,inbus,phasebus,buf,samples);
	}
	initPSSamplingStrip {
		arg gr,bs,ib,pb,bf,samps;
		[\init].postcs;
		gr.notNil.if({
			[\gr1, gr].postcs;
			server = gr.server;
		}, {
			[\gr2, gr].postcs;
			server = Server.default;
		});
		[\server, server, server.sampleRate].postcs;
		all[id] = this;
		otherstuff2free = Array.new;		
		server.makeBundle(0.0, { // nil executes ASAP
			gr.isNil.if({
				//group  = this.freeable(Group.new(server));
				group = Group.new(server);
				this.freeable(group);
				[\gg1, gr, group].postcs;
			}, {
				group = gr;
				[\gg2, gr, group].postcs;
			});			
			[\group, group].postcs;
			sourcegroup=this.freeable(Group.head(group));
			[\sourcegroup, sourcegroup].postcs;
			fxgroup=this.freeable(Group.after(sourcegroup));
			mixergroup=this.freeable(Group.tail(fxgroup));
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
			
		});
		jacksynth = this.freeable((
			instrument: \jack__1,
			in: inbus,
			out: bus,
			group: sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).postcs.play);
		
		inputgainsynth = this.freeable((
			instrument: \limi__1x1,
			pregain: 10.dbamp,
			out: bus,
			group: sourcegroup,
			addAction: \addToTail,
			sendGate: false,//persist
		).postcs.play);
		
		samples.notNil.if({
			sourcesoundsynth = this.freeable((
				instrument: \bufrd_or_live__1x1,
				looptime: this.beat2sec(16),
				offset: 0.0,
				in: inbus,
				out: bus,
				group: inputgainsynth,
				addAction: \addToHead,
				bufnum: samples.at(0),
				livefade: 0.0,
				loop: 1,
				sendGate: false,//persist
			).postcs.play);
		});
		
		recsynth = this.freeable((
			instrument: \ps_bufwr_resumable__1x1,
			in: bus,
			bufnum: buffer,
			phasebus: \addToTail,
			fadetime: 0.05,
			group: fxgroup,
			addAction: \addToTail,
			sendGate: false,//persist
		).postcs.play);
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
