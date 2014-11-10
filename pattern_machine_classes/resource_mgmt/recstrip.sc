//A particular sampling doohickey;
//No sample path between mono input and stereo output;
//that comes from resampling the sample buffer.
PSSamplingStrip {
	var <id;
	var <state;
	var <clock;
	var <group;
	var <headgroup, <midgroup, <tailgroup;
	var <numChannels=2;// internal/output channels that is.
	var <bus, <listenbus, <inbus, <outbus, <phasebus;
	var <audiobuf;
	var <samples;
	var <server;
	var <otherstuff2free;
	var <recstrip, <playstrip;
	var <injacksynth, <outjacksynth, <recsynth, <inputgainsynth, <sourcesoundsynth;
	
	classvar <idCount=0;
	classvar <all;
	
	*initClass {
		StartUp.add({
			all = IdentityDictionary.new;
		});
	}
	//inbus and outbus presumed shared. other mangling happens within.
	*new {
		arg id, state, clock, group, bus, listenbus, inbus, outbus, phasebus, samples, audiobuf;
		id = id ?? {idCount = idCount + 1;};
		this.removeAt(id);
		state ?? {state = Event.new(n:60, know: true)};
		clock ?? {clock = TempoClock.default};
		^super.newCopyArgs(
			id, state, clock
		).initPSSamplingStrip(group,bus,listenbus,inbus,outbus,phasebus,samples,audiobuf);
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
	setupBundle {
		arg gr,bs,lb,ib,ob,pb,samps,bf;
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
		lb.isNil.if({
			listenbus = this.freeable(Bus.audio(server, 1));
		}, {
			listenbus = lb;
		});
		ib.isNil.if({
			inbus = this.freeable(Bus.audio(server, 1));
		}, {
			inbus = ib;
		});
		ob.isNil.if({
			outbus = this.freeable(Bus.audio(server, numChannels));
		}, {
			outbus = ob;
		});
		pb.isNil.if({
			phasebus = this.freeable(Bus.control(server, 1));
		}, {
			phasebus = pb;
		});
		bf.isNil.if({
			audiobuf  = this.freeable(
				Buffer.alloc(server, server.sampleRate * 60.0, 1)
			);
		}, {
			audiobuf = bf;
		});
		injacksynth = this.freeable(Synth.new(
			"jack__1",
			(
			in: listenbus,
			out: inbus,
			).getPairs,
			target: headgroup,
			addAction: \addToHead,
		));
		//['jacksynth', jacksynth].postcs;
		inputgainsynth = this.freeable(Synth.new(
			"limi__1x1",
			(
			pregain: 10.dbamp,
			out: inbus,
			).getPairs,
			target: injacksynth,
			addAction: \addAfter,
		));
		//['inputgainsynth', inputgainsynth].postcs;
		samps.notNil.if({
			samples = samps;
			sourcesoundsynth = this.freeable(Synth.new(
				"bufrd_or_live__1x1",
				(
				looptime: this.beat2sec(16),
				offset: 0.0,
				out: inbus,
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
			"ps_bufwr_resumable__1x1",
			(
			in: inbus,
			bufnum: audiobuf,
			phasebus: phasebus,
			fadetime: 0.05,
			).getPairs,
			target: headgroup,
			addAction: \addToTail,
		));
		//note no connection to the outside world
		outjacksynth = this.freeable(Synth.new(
			"jack__%".format(numChannels),
			(
				in: bus,
				out: outbus,
			).getPairs,
			target: tailgroup,
			addAction: \addToTail,
		));
	}
	initPSSamplingStrip {
		arg gr,bs,lb,ib,ob,pb,samps,bf;
		gr.notNil.if({
			server = gr.server;
		}, {
			server = Server.default;
		});
		all[id] = this;
		otherstuff2free = Array.new;
		server.makeBundle(nil, {
			this.setupBundle(gr,bs,lb,ib,ob,pb,samps,bf);
		});
	}
	rec {|dur=10.0|
		recsynth.set(\t_rec, dur);
	}
	sourceBuf {
		arg ...selector;
		sourcesoundsynth.set(\bufnum, samples.at(*selector));
	}
	free {
		otherstuff2free.do({arg stuff; stuff.free});
	}
	freeable {|stuff|
		otherstuff2free = otherstuff2free.add(stuff);
		^stuff;
	}
	// acting synthish
	asTarget {
		^midgroup;
	}
	asGroup {
		^midgroup;
	}
	asBus {
		^bus;
	}
	baseEvent {
		//Do I really want to return all state? Can be a messy dict.
		^(
			out: bus,
			group: midgroup,
			now: phasebus.asMap,
			bufnum: audiobuf,
			addAction: \addToTail, 
		);
	}
	////debugging nice
	printOn { |stream|
		stream << this.class.asString <<"(id:" << id.asString << ")";
	}
	
	//utility conversions
	beat2sec {|beats| ^beats/(clock.tempo)}
	sec2beat {|secs| ^secs * (clock.tempo)}
	beat2freq {|beats| ^(clock.tempo)/beats}
	freq2beat {|freq| ^(clock.tempo) / freq}
}
