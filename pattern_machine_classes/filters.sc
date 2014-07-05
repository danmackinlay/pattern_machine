// http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Calculating-OnePole-coefficient-for-one-pole-LP-HP-filter-td4034000.html
//see also http://www.dspguide.com/
//One pole LPF and HPF filters with freq input (instead of coef)
//Thanks to Volker B�hm for the (freq -> coef) conversion formula.
//And Batuhan Bozkurt for initial pseudo ugen
//these all take an "iter" param telling you how many times to apply the damn filter
OpLPF {
	*kr {|in, freq=100, iter=1, mul=1, add=0|
		var coef = exp(-2pi * (freq * ControlDur.ir));
		iter.do({in=OnePole.kr(in, coef);});
		^in;
	}
	*ar {|in, freq|
		var coef = exp(-2pi * (freq * SampleDur.ir));
		iter.do({in=OnePole.ar(in, coef);});
		^in;
	}
}

OpHPF {
	*kr {|in, freq=100, mul=1, add=0|
		var coef = exp(-2pi * (freq * ControlDur.ir)));
		iter.do({in=in - OnePole.kr(in, coef);});
		^in;
	}
	*ar {|in, freq|
		var coef = exp(-2pi * (freq * SampleDur.ir)));
		iter.do({in=in - OnePole.kr(in, coef);});
		^in;
	}
}