// NB this currently assumes the chord list is exhaustive! need to change that
(
var state = ();
~state = state;
state.make({
	var data = (
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers" +/+ "chordmap_data.scd")
	).flop;
	~idfromrow=data.removeAt(0);
	~rowfromid=IdentityDictionary.new(n=~idfromrow.size);
	~idfromrow.do({|id,row|~rowfromid[id]=row;});
	~map=data.flop.collect({|r|r.asFloatArray});
	~chordIdNeighboursOfCoord = {|self, center, rangesq=0.5|
		var candidates=Array.new, dists=Array.new, distorder;
		self.map.do({|row, i|
			var distsq = (row-center).squared.sum;
			(distsq<rangesq).if({
				candidates = candidates.add(self.idfromrow[i]);
				dists = dists.add(distsq);
			});
		});
		distorder = dists.order;
		[candidates[distorder], dists[distorder]].flop;
	};
	~chordIdNeighboursOfChordId = {|self, chordId, rangesq=0.5|
		self.chordIdNeighboursOfCoord(self.map[self.rowfromid[chordId]], rangesq);
	};
	~chordIdNeighboursOfClass = {|self, class, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromClass(class)],
			rangesq);
	};
	//Check this one.
	~classNeighboursOfClass = {|self, class, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[self.rowfromid[self.chordIdFromClass(class)]],
			rangesq).collect({|idDist| [self.classFromChordId(idDist[0]), idDist[1]]});
	};
	~classNeighboursOfCoord = {|self, center, rangesq=0.5|
		var ret;
		ret = self.chordIdNeighboursOfCoord(center, rangesq);
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
~state.idfromrow[65];
~state.map.flop.collect(_.maxItem);
~state.map.flop.collect(_.minItem);
~state.classNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.classNeighboursOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
~state.chordIdNeighboursOfCoord([ -1.0207888991954, -0.73112531959605 ], 0.5).flop[0];
~state.chordIdNeighboursOfCoord([ 3.3441033974773, 0.93656058383309 ], 0.5).flop[0];
(
var state = ~state;
state.chordspiral = Pspawner({|spawner|
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
		inf.do({
			var freqs;
			~time = ~time + ~interval;
			freqs = Array.series(~dims, ~basef, ~basef/17.0);
			~coord = (freqs*~time).cos*~range + ~center;
			~class = state.classNeighboursOfCoord(~coord, 0.5)[0][0];
			~pitches = ~class;// + 60;
			[~time, ~coord, freqs, ~class, ~pitches].postln;
			spawner.seq((
				dur: ~interval,
				legato: 1,
				note: ~pitches
			));
		});
	});
}).play;
)

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
