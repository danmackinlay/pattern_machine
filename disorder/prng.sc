// Linear Congruential
// Lifted in spirit if not details from chaos lib, runs at sensible, non-audio rates
// TODO: demand-rate. 

LinCongRNG  {
	var <>a;
	var <>c;
	var <>m;
	var <>state;
	step { 
		state = ((a*state)+c)%m;
		^state;
	}
	nextN {|n=1|
		^n.collect(this.step)
	}
	next {|xi|
		//get next val and optionally update with new one
		state = xi ? state;
		^this.step
	}
	*new {|a=8.117111, c=0.23335, m=1.0, state = 0.49687|
		^super.newCopyArgs(a,c,m,state);
	}
}