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
		self.chordIdNeighboursOfCoord(self.map[~rowfromid[chordId]], rangesq);
	};
	~chordIdNeighboursOfClass = {|self, class, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[~rowfromid[self.chordIdFromClass(class)]],
			rangesq);
	};
	~classNeighboursOfClass = {|self, class, rangesq=0.5|
		self.chordIdNeighboursOfCoord(
			self.map[~rowfromid[self.chordIdFromClass(class)]],
			rangesq).collect({|idDist| [self.classFromChordId(idDist[0]), idDist[1]]});
	};
	~classNeighboursOfCoord = {|self, center, rangesq=0.5|
		self.chordIdNeighboursOfCoord(center, rangesq).collect(
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

~state.chordIdNeighboursOfCoord([0,0],0.5);
~state.classNeighboursOfCoord([0,0],0.5);
~state.chordIdNeighboursOfChordId(1, 0.1);
~state.classFromChordId(185);
~state.chordIdFromClass([0,3,4,5,7]);
~state.classNeighboursOfClass([0,3,4,5,9]);
4096.collect({|i|
	i==~state.chordIdFromClass(~state.classFromChordId(i));
}).every(_);
