+ Array {
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
