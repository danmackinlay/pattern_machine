FitnessSpec : ControlSpec {
  *initClass {
    specs.addAll([
      \fitness -> ControlSpec(0, 10000)
      , \evalperiod -> ControlSpec.new(0.01, 100, \exponential, nil, 1)
    ])
  }
}
/*IntervalSpec : StaticSpec {
  *initClass {
    specs.addAll([\evalperiod -> StaticSpec.new(0.01, 100, \exponential, nil, 1)])
  }
}*/