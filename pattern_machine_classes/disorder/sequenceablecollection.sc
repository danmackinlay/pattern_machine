/*
 * round to member of this collection
 [1,2,4].nearestLog(2.5)
 */

+ SequenceableCollection {
	nearestLin { arg val;
		//approximate a val by a member of this collection
		//assume this collection is sorted
		^this.at(this.indexIn(val));
	}
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
	
}