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
	var data = (
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers" +/+ "spectral_embed_dist_3.scd")
	).flop;
	~idfromrow=data.removeAt(0);
	~midiout=MIDIOut.newByName("IAC-Driver", "Bus 1"
	).latency_(Server.default.latency);
	~rowfromid=IdentityDictionary.new(n=~idfromrow.size);
	~idfromrow.do({|id,row|~rowfromid[id]=row;});
	~map=data.flop.collect({|r|r.asFloatArray});
	~chordIdNeighboursOfCoord = {|self, center, limCount=15, limDist=inf|
		var candidates, limDistSq=limDist.squared;
		candidates = SortedList.new(limCount+1, {|item1, item2| item1[1]<item2[1]});
		self.map.do({|row, i|
			var distsq = (row-center).squared.sum;
			candidates = candidates.add([self.idfromrow[i], distsq]);
			//candidates = candidates[..limCount];
		});
		candidates[..(limCount-1)].select({|item| item[1]<limDistSq}).asArray;
		//candidates;
	};
	~chordIdNeighboursOfChordId = {|self, chordId, limCount=15, limDist=inf|
		self.chordIdNeighboursOfCoord(self.map[self.rowfromid[chordId]], limCount, limDist);
	};
	~chordIdNeighboursOfClass = {|self, class, limCount=15, limDist=inf|
		self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromClass(class)],
			limCount, limDist);
	};
	//Check this one before using; not tested since I messed with indices.
	~classNeighboursOfClass = {|self, class, limCount=15, limDist=inf|
		self.chordIdNeighboursOfCoord(
			self.map[self.rowfromid[self.chordIdFromClass(class)]],
			limCount, limDist
		).collect({|idDist| [self.classFromChordId(idDist[0]), idDist[1]]});
	};
	~classNeighboursOfCoord = {|self, center, limCount=15, limDist=inf|
		var ret;
		ret = self.chordIdNeighboursOfCoord(center, limCount, limDist);
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
	~interval = 1;
	~maxDist = 0.1;
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
			~coord = (~rates * ~time).cos * ~range + ~center;
			~neighbours = state.classNeighboursOfCoord(~coord, 1, 0.2);
			(~neighbours.size>0).if({
				~bestclass = ~neighbours[0][0];
				~bestdist = ~neighbours[0][1];
				~notes = ~bestclass;
				[~time, ~coord, ~bestdist, ~bestclass, ~notes].postln;
				spawner.seq(
					state.protoEvent.copy.putAll((
						dur: ~interval,
						note: ~notes,
					))
				);
			}, {
				[\nonotes, ~time, ~coord].postln;
				spawner.wait(~interval);
			});

		});
	});
}).trace.play;
//this doesn't seem to happen by isself reliably
CmdPeriod.doOnce(
	~state.protoEvent.copy.putAll((
		midicmd: \allNotesOff,
	).play);
);
)
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

~state.map
~state.idfromrow[65];
~state.map.flop.collect(_.maxItem);
~state.map.flop.collect(_.minItem);
~state.classNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0).flop[0];
~state.classNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.classNeighboursOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
~state.chordIdNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 1, 0.3).flop[0];
~state.chordIdNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.chordIdNeighboursOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
~state.chordIdNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5);

GNUPlot
Quarks.gui

(pitch:[ 0, 2, 5, 6, 8 ]).play;
~state.chordIdNeighboursOfCoord([0,0],0.5);
~state.classNeighboursOfCoord([0,0],0.5);
~state.chordIdNeighboursOfChordId(1, 0.1);
~state.classFromChordId(185);
~state.chordIdFromClass([0,3,4,5,7]);
~state.classNeighboursOfClass([0,3,4,5,9]);
4096.collect({|i|
	i==~state.chordIdFromClass(~state.classFromChordId(i));
}).every(_);
