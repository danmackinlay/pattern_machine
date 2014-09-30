// >>> chord_notes_from_ind(17)
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
		[candidates[distorder], dists[distorder]];
	};
	~chordIdNeighboursOfChordId = {|self, chordId, rangesq=0.5|
		self.chordIdNeighboursOfCoord(self.map[chordId], rangesq);
	};
	~chordIdNeighboursOfNotes = {|self, notes, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromNotes(notes)],
			rangesq);
	};
	~notesNeighboursOfNotes = {|self, notes, rangesq=0.5|
		var candidates, dists;
		# candidates, dists = self.chordIdNeighboursOfCoord(
			self.map[self.chordIdFromNotes(notes)],
			rangesq);
		[candidates.collect({|id| self.notesFromChordId(id)}), dists];
	};
	~notesNeighboursOfCoord = {|self, chordId, rangesq=0.5|
		var candidates, dists;
		# candidates, dists = self.chordIdNeighboursOfCoord(
			self.map[chordId], rangesq
		);
		[candidates.collect({|id| self.notesFromChordId(id)}), dists];
	};
	~notesFromChordId = {|self, chordId|
		chordId.asBinaryDigits(12).reverse.collect(
			{|v,i| (v>0).if(i)}
		).select(_.notNil);
	};
	~chordIdFromNotes = {|self, notes|
		var arr=Array.fill(12,0);
		arr[notes]=1;
		arr.reverse.convertDigits(2);
	};
});
)

~state.chordIdNeighboursOfChordId(1, 0.1);
~state.notesFromChordId(185);
~state.chordIdFromNotes([0,3,4,5,7]);
~state.notesNeighboursOfNotes([0,3,4,5,7]);
4096.collect({|i|
	i==~state.chordIdFromNotes(~state.notesFromChordId(i));
}).every(_);
