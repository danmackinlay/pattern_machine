//TODO: display info

/*
// for mac users who want X:
GNUPlot.initCode    = GNUPlot.initCode ++ "\n set term x11 \n";
GNUPlot.gnuplotpath = GNUPlot.pathToXLauncher.quote + "/opt/local/bin/gnuplot";
*/

MIDIClient.destinations;
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
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers/mappings" +/+ "spectral_embed_dist_corr_2_impurity_alt.scd")
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
	~classNeighboursOfClass = {|self, class, limCount=15, limDist=inf|
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
	~maxes=~map.flop.collect(_.maxItem);
	~mins=~map.flop.collect(_.minItem);
	~center = (~maxes+~mins)/2;
	~range = (~maxes-~mins)/2;
	~coord=Array.fill(~dims,0.0);
	~time = 0.0;
	~basef = 1/10;
	~interval = 1/4;
	~maxDist = 0.1;
	~offset = 150.0.rand;
});
state.chordspiral = Pspawner({|spawner|
	~state.use({
		//link::Tutorials/A-Practical-Guide/PG_Cookbook04_Sending_MIDI::
		~heldPitches = IdentitySet.new(12);
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
			~coord = (~rates * ~time + ~offset).cos * ~range + ~center;
			~neighbours = state.classNeighbourOfCoord(~coord, 1, 0.2);
			(~neighbours.size>0).if({
				~bestclass = ~neighbours[0][0];
				~bestdist = ~neighbours[0][1];
				~notes = ~bestclass;
				[~time, ~coord, ~bestdist, ~bestclass, ~notes, ~offset].postln;
				~ev = ~protoEvent.copy;
				~ev.putAll((
					dur: ~interval,
					note: ~notes,
				));
				//[\ev, ~ev].postln;
				spawner.seq(
					~protoEvent.copy.putAll(~ev);
				);
			}, {
				[\nonotes, ~time, ~coord].postln;
				spawner.wait(~interval);
			});

		});
	});
}).trace.play;
//this doesn't seem to happen by isself reliably
CmdPeriod.doOnce({
	var ev = ~state.protoEvent.copy;
	ev.putAll((
		midicmd: \allNotesOff,
	)).play;
});
)

~state.map[0].size;
~state.map.flop.collect(_.maxItem);
~state.map.flop.collect(_.minItem);
~state.map.flop.collect(_.mean);
~state.map.flop.collect(_.stdDevPop * 2);
~state.tree.nearest([1,1,1,1]);

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
