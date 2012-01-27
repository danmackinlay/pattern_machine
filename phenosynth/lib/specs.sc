/* are these used at all any more? Now that I am not using Instr, I'm not sure they are useful
*/
FitnessSpec : ControlSpec {
	*initClass {
		specs.addAll([
			\fitness -> ControlSpec(0, 10000),
			\evalperiod -> ControlSpec.new(0.01, 100, \exponential, nil, 1)
		])
	}
}
/*IntervalSpec : StaticSpec {
	*initClass {
		specs.addAll([\evalperiod -> StaticSpec.new(0.01, 100, \exponential, nil, 1)])
	}
}*/