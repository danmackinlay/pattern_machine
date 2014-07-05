// http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Calculating-OnePole-coefficient-for-one-pole-LP-HP-filter-td4034000.html
//see also http://www.dspguide.com/
//One pole LPF and HPF filters with freq input (instead of coef)
//Thanks to Volker Bšhm for the (freq -> coef) conversion formula.
//And Batuhan Bozkurt for initial pseudo ugen
OpLPF {
	*kr {|in, freq|
		^OnePole.ar(in, exp(-2pi * (freq * ControlDur.ir)));
	}
	*ar {|in, freq|
		^OnePole.ar(in, exp(-2pi * (freq * SampleDur.ir)));
	}
}

OpHPF {
	*kr {|in, freq|
		^(in - OnePole.ar(in, exp(-2pi * (freq * ControlDur.ir))));
	}
	*ar {|in, freq|
		^(in - OnePole.ar(in, exp(-2pi * (freq * SampleDur.ir))));
	}
}