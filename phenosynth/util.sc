+ Dictionary {
	updateFrom {|updates|
		//update this Dictionary's keys from another dictionary's.
		updates.keysValuesDo({|key, val| this[key] = val;});
		^this;
	}
	updatedFrom {|updates|
		//return a copy of this dictionary, updated from this other dictionary passed in.
		^this.copy.updateFrom(updates);
	}
}