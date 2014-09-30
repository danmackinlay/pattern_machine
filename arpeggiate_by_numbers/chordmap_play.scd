// >>> chord_classes_from_ind(17)
// array([0, 4], dtype=uint64)
17.asBinaryDigits(12).reverse.collect({|v,i| (v>0).if(i) }).select(_.notNil);
[1,0,1,1].convertDigits(2);
~a=Array.fill(12,0);
~a[[0,4]]=1
(
var state = ();
~state = state;
state.make({
	~map = (
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers" +/+ "chordmap_data.scd")
	).collect({|row| row.asFloatArray});
	~chordIdNeighboursOfCoord = {|self, center, rangesq=0.5|
		var candidates=Array.new, dists=Array.new, distorder;
		self.map.do({|row, i|
			var distsq = row.squared.sum;
			(distsq<rangesq).if({
				candidates = candidates.add(i);
				dists = dists.add(distsq);
			});
		});
		distorder = dists.order;
		[candidates[distorder], dists[distorder]].flop;
	};
	~chordIdNeighboursOfChordId = {|self, chordId, rangesq=0.5|
		self.chordIdNeighboursOfCoord(self.map[chordId], rangesq);
	};
	~chordIdNeighboursOfClasses = {|self, classes, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromClasses(classes)],
			rangesq);
	};
	~classesNeighboursOfClasses = {|self, classes, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromClasses(classes)],
			rangesq).collect({|idDist| [self.classesFromChordId(idDist[0]), idDist[1]]});
	};
	~classesNeighboursOfCoord = {|self, chordId, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[chordId], rangesq
		).collect({|idDist| [self.classesFromChordId(idDist[0]),idDist[1]]});
	};
	~classesFromChordId = {|self, chordId|
		chordId.asBinaryDigits(12).reverse.collect(
			{|v,i| (v>0).if(i)}
		).select(_.notNil);
	};
	~chordIdFromClasses = {|self, classes|
		var arr=Array.fill(12,0);
		arr[classes]=1;
		arr.reverse.convertDigits(2);
	};

});
)

[[1,2,3],[4,5,6]].flop.flop

~state.chordIdNeighboursOfChordId(1, 0.1);
~state.classesFromChordId(185);
~state.chordIdFromClasses([0,3,4,5,7]);
~state.classesNeighboursOfClasses([0,3,4,5,7]);
4096.collect({|i|
	i==~state.chordIdFromClasses(~state.classesFromChordId(i));
}).every(_);
