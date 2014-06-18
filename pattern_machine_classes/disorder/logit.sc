//inv-S curve
InvLogit {
	*new{|x=0.5|
		^(x/(1-x)).log;
	}
}
//S-curve
Logit {
	*new{|x=0|
		^1/(1+x.neg.exp);
	}
}