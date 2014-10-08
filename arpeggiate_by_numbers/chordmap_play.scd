//TODO: display info

MIDIClient.destinations;
MIDIClient.sources;
(
var state = ();
~state = state;
MIDIClient.init;

state.make({
	~midiout=MIDIOut.newByName("IAC-Driver", "Bus 1"
		).latency_(Server.default.latency);
	~data = (
		//this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_dist_3.scd")
		//this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_dist_3.scd")
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_dist_corr_2_impurity_alt.scd") //PRETTY
		//this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_dist_corr_2_impurity_lin.scd") //MEH
		//this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_prod_corr_2_impurity_alt.scd") // cone; needs coord transform
		//this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_prod_corr_2_impurity_lin.scd") //Squid-shaped
	).flop;
	~idfromrow = ~data.removeAt(0);
	~rowfromid=IdentityDictionary.new(n=~idfromrow.size);
	~idfromrow.do({|id,row|~rowfromid[id]=row;});
	~map = ~data.copyRange(0,(~data.size-1)).flop.collect({|r, i| r.asFloatArray});
	~tree = KDTree(~data.add(~idfromrow).flop, lastIsLabel: true);
	~chordIdNeighbourOfCoord = {|self, center, limDist=inf|
		var node, dist;
		# node, dist = ~tree.nearest(center);
		(dist<=limDist).if({
			[[node.label, dist]]
		}, {
			[]
		});
	};
	~chordIdNeighboursOfChordId = {|self, chordId, limDist=inf|
		self.chordIdNeighbourOfCoord(self.map[self.rowfromid[chordId]], limDist);
	};
	~chordIdNeighboursOfClass = {|self, class, limDist=inf|
		self.chordIdNeighbourOfCoord(
			self.map[self.chordIdFromClass(class)],
			limDist);
	};
	//Check this one before using; not tested since I messed with indices.
	~classNeighboursOfClass = {|self, class, limDist=inf|
		self.chordIdNeighbourOfCoord(
			self.map[self.rowfromid[self.chordIdFromClass(class)]],
			limDist
		).collect({|idDist| [self.classFromChordId(idDist[0]), idDist[1]]});
	};
	~classNeighbourOfCoord = {|self, center, limDist=inf|
		var ret;
		ret = self.chordIdNeighbourOfCoord(center, limDist);
		ret.collect(
			{|idDist| [self.classFromChordId(idDist[0]),idDist[1]]}
		);
	};
	~classFromChordId = {|self, chordId|
		chordId.asBinaryDigits(12).reverse.collect(
			{|v,i| (v>0).if(i)}
		).select(_.notNil);
	};
	~chordIdFromClass = {|self, class|
		var arr=Array.fill(12,0);
		arr[class]=1;
		arr.reverse.convertDigits(2);
	};
});
)

(
var state = ~state;
~state.use({
	~dims = ~map[0].size;
	~maxes = ~map.flop.collect(_.maxItem);
	~mins = ~map.flop.collect(_.minItem);
	//~center = (~maxes+~mins)/2;
	//~scale = (~maxes-~mins)/2;
	~center = ~map.flop.collect(_.mean);
	~scale = ~map.flop.collect(_.stdDevPop * 2);
	~coord = Array.fill(~dims,0.0);
	~time = 0.0;
	~basef = 1/10;
	~interval = 1/4;
	~maxDist = 0.1;
	~offset = 150.0.rand;
	~manualparam = Array.fill(4, 0.0);
	~manualcoord = Array.fill(~dims, 0.0);
	~auto = 0;
	~verbose = true;
	~octavestartparam=0.0;
	~octaverangeparam=0.0;
	~octavestart = 64;
	~octaveend = 76;
	~nnotes = 6; //upper bound
});
state.chordspiral = Pspawner({|spawner|
	~state.use({
		//link::Tutorials/A-Practical-Guide/PG_Cookbook04_Sending_MIDI::
		~protoEvent = (
			type: \midi,
			legato: 0.8,
			midiout: ~midiout,
			db: -10.0,
			chan: 0,
			midicmd: \noteOn,
			//velocity: 64,
		);
		inf.do({
			~time = ~time + ~interval;
			~rates = Array.series(~dims, ~basef, ~basef/17.0);
			~autocoord = ((~rates * ~time + ~offset).cos * ~scale + ~center);
			~manualcoord = ~manualparam.copyRange(0,~dims-1) * ~scale + ~center;
			~coord = (~autocoord * ~auto) + (~manualcoord * (1 - ~auto));
			//~neighbours = state.classNeighbourOfCoord(~coord, limDist: 1);
			~neighbours = state.classNeighbourOfCoord(~coord);
			//The 2nd term in the test filters out the empty class
			((~neighbours.size>0) && (~neighbours[0][0].size>0)).if({
				~verbose.if({[~neighbours].postln;});
				~bestclass = ~neighbours[0][0];
				~bestdist = ~neighbours[0][1];
				~octavestart = ~octavestartparam.linlin(0.0, 1.0, 20.0, 105.0).floor;
				~octaveend = ~octaverangeparam.linlin(0.0, 1.0, ~octavestart+12, 127.0).floor;
				~notes = IdentitySet.newFrom(~nnotes.collect({(~bestclass.choose + (30.rand * 12)).offsetModBase(~octavestart, ~octaveend)})).asArray;
				~verbose.if({[~time, ~coord, ~bestdist, ~bestclass, ~octavestart, ~octaveend, ~notes].postln;});
				~ev = ~protoEvent.copy;
				~ev.putAll((
					dur: ~interval,
					midinote: ~notes,
				));
				//[\ev, ~ev].postln;
				spawner.seq(
					~protoEvent.copy.putAll(~ev);
				);
			}, {
				~verbose.if({[\nonotes, ~time, ~coord].postln;});
				spawner.wait(~interval);
			});

		});
	});
}).play;
state.use({
	~alldefs = List.new;
	~sliderInPort = {
		MIDIClient.init;
		MIDIIn.connectAll;
		MIDIIn.findPort("nanoKONTROL2", "SLIDER/KNOB");
	}.value;
	//MIDIFunc.trace(true);
	MIDIFunc.trace(false);
	~sliderMeta = [
		[1,  0],//slider 1
		[1, 16],//knob 1
		[1,  1],//slider 2
		[1, 17],//knob 2
		[1,  2],//etc
		[1, 18],
		[1,  3],
		[1, 19],
		[1,  4],
		[1, 20],
		[1,  5],
		[1, 21],
		[1,  6],
		[1, 22],
		[1,  7],
		[1, 23],
	];
	//location the first 3-4 faders
	~alldefs.add(MIDIdef.cc(\param0, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		state.manualparam[0] = mapped;
		//[\param0, mapped].postln;
	}, ccNum: 0, chan: 1));
	~alldefs.add(MIDIdef.cc(\param1, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		state.manualparam[1] = mapped;
		//[\param1, mapped].postln;
	}, ccNum: 1, chan: 1));
	~alldefs.add(MIDIdef.cc(\param2, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		state.manualparam[2] = mapped;
		//[\param2, mapped].postln;
	}, ccNum: 2, chan: 1));
	~alldefs.add(MIDIdef.cc(\param3, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,-1.0,1.0);
		state.manualparam[3] = mapped;
		//[\param3, mapped].postln;
	}, ccNum: 3, chan: 1));
	~alldefs.add(MIDIdef.cc(\octavestart, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		state.octavestartparam = mapped;
		[\octavestart, mapped].postln;
	}, ccNum: 4, chan: 1));
	~alldefs.add(MIDIdef.cc(\octaverange, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,0.0,1.0);
		state.octaverangeparam = mapped;
		[\octaverange, mapped].postln;
	}, ccNum: 5, chan: 1));
	~alldefs.add(MIDIdef.cc(\nnotes, {|val,num,chan,src|
		var mapped = val.linlin(0.0,127.0,1,17).asInteger;
		state.nnotes = mapped;
		[\nnotes, mapped].postln;
	}, ccNum: 6, chan: 1));

});
//this doesn't seem to happen by isself reliably
CmdPeriod.doOnce({
	var ev = ~state.protoEvent.copy;
	ev.putAll((
		midicmd: \allNotesOff,
	)).play;
});
)
~state.auto=0;
~state.auto=1;
~state.manualparam;
~state.sliderInPort;

~state.map[0].size;
~state.map.flop.collect(_.maxItem);
~state.map.flop.collect(_.minItem);
~state.map.flop.collect(_.mean);
~state.map.flop.collect(_.stdDevPop * 2);
~state.tree.nearest([1,1,1,1]);

/*
// for mac users who want X:
GNUPlot.initCode    = GNUPlot.initCode ++ "\n set term x11 \n";
GNUPlot.gnuplotpath = GNUPlot.pathToXLauncher.quote + "/opt/local/bin/gnuplot";
*/

(
~state.use({
	~plotter = GNUPlot.new;
	~plotter.sendCmd("set xrange [%:%]".format(~mins[0], ~maxes[0]));
	~plotter.sendCmd("set yrange [%:%]".format(~mins[1], ~maxes[1]));
	(~dims>2).if({
		~plotter.sendCmd("set zrange [%:%]".format(~mins[2], ~maxes[2]));
	});
	~plotworker = Routine.new({
		loop {
			~plotter.scatter(~map);
			~plotter.replot;
			//state.locs = locs;
			(0.5).yield;
		};
	}).play(AppClock);
});
)
~state.plotter.plot3(~state.map);

~state.offset=135;
~state.interval=1/4;
~state.idfromrow[65];
~state.classNeighbourOfCoord([ -1.0207888991954, -0.73112531959605 ], 0).flop[0];
~state.classNeighbourOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.classNeighbourOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
~state.chordIdNeighbourOfCoord([ -1.0207888991954, -0.73112531959605 ], 1, 0.3).flop[0];
~state.chordIdNeighbourOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.chordIdNeighbourOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
~state.chordIdNeighbourOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5);
~state.map;
~state.dim;
~state.tree.nearest([0,0,0])

(pitch:[ 0, 2, 5, 6, 8 ]).play;
~state.chordIdNeighbourOfCoord([0,0],0.5);
~state.classNeighbourOfCoord([0,0],0.5);
~state.chordIdNeighboursOfChordId(1, 0.1);
~state.classFromChordId(185);
~state.chordIdFromClass([0,3,4,5,7]);
~state.classNeighboursOfClass([0,3,4,5,9]);
4096.collect({|i|
	i==~state.chordIdFromClass(~state.classFromChordId(i));
}).every(_);
