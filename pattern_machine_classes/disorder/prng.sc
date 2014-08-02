// Linear Congruential 
// Lifted in spirit if not details from chaos lib, runs at sensible, non-audio rates
// TODO: demand-rate pseudo-UGen

LinCongRNG  {
	var <>a;
	var <>c;
	var <seed;
	transform{|inseed|
		^((a*inseed)+c).wrap(0.0,1.0);
	}
	next {
		seed = this.transform(seed);
		^seed;
	}
	nextN {|n=1|
		^n.collect({this.next});
	}
	*new {|a=8.117111, c=0.23335, seed=nil|
		var n = super.newCopyArgs(a,c,seed??{1.0.rand});
		n.next;
		^n;
	}
}

//LinCongRNG mapped to a possibly-even-less well-behaved but very useful continuous version; sorta the generalised tent-map version of the LCG
SawRNG : LinCongRNG {
	transform{|inseed|
		^((a*inseed)+c).fold(0.0,1.0);
	}
}