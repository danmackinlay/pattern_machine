// Linear Congruential 
// Lifted in spirit if not details from chaos lib, runs at sensible, non-audio rates
// TODO: demand-rate. 

LinCongRNG  {
	var <>a;
	var <>c;
	var <>m;
	var <>seed;
	next {
		seed = ((a*seed)+c)%m;
		^seed;
	}
	nextN {|n=1|
		^n.collect({this.next});
	}
	*new {|seed=0.49687, a=8.117111, c=0.23335, m=1.0|
		var n = super.newCopyArgs(a,c,m,seed);
		n.next;
		^n;
	}
}