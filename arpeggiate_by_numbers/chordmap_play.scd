9.asBinaryDigits(12)
(
var state = ();
~state = state;
state.make({
	~map = (
		this.executeFile(PS.pmpath +/+ "arpeggiate_by_numbers" +/+ "chordmap_data.scd")
	).collect({|row| row.asFloatArray});
	~neighboursOfCoord = {|self, center, rangesq=0.5|
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
	~neighboursOfChordId = {|self, chordId, rangesq=0.5|
		self.neighboursOfCoord(self.map[chordId], rangesq);
	};
});
)

~state.neighboursOfChordId(1, 0.1);