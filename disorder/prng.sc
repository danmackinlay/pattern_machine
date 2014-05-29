// Linear Congruential 
// Lifted in spirit if not details from chaos lib, runs at sensible, non-audio rates
// TODO: demand-rate. 

LinCongRNG  {
	var <>a;
	var <>c;
	var <>m;
	var <>seed;
	step {
		seed = ((a*seed)+c)%m;
		^seed;
	}
	nextN {|n=1|
		^n.collect(this.step)
	}
	next {|xi|
		//get next val and optionally update with new one
		seed = xi ? seed;
		^this.step
	}
	*new {|seed=0.49687, a=8.117111, c=0.23335, m=1.0|
		super.newCopyArgs(a,c,m,seed);
	}
}