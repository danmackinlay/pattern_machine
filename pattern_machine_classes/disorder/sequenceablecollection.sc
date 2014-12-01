
+ SequenceableCollection {
	/*
	 * round to member of this collection
	 [1,2,4].nearestLog(2.5)
	 */
	
	nearestLin { arg val;
		//approximate a val by a member of this collection
		//assume this collection is sorted
		^this.at(this.indexIn(val));
	}
	/*
	 * round to member of this collection
	 [1,2,4].nearestLog(2.5)
	 */
	
	nearestLog { arg val;
		var logval, left, right, idx = this.indexInBetween(val);
		logval = val.log;
		left = this.at(idx.floor);
		right = this.at(idx.ceil);
		((logval-(left.log))>(right.log-logval)).if({
			^right
		},{
			^left
		});
	}
	unif {|p|
		/*
		uniform lookup, as if this were a discrete pdf
		same as choose, but BYO lookup index in [0,1]
		TODO: weighted version
		[1,2,-3].unif(1.0)==-3;
		[1,2,-3].unif(1.0)==-3;
		*/
		var size = this.size;
		^this.at((p*size).floor.clip(0, size-1));
	}
}