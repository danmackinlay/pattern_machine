Instr.new(
  "phenosynth.listeners.default",
  {|in, evalPeriod = 1|
    LagUD.ar(
      Convolution.ar(in, SinOsc.ar(500), 1024, 0.5).abs,
      evalPeriod/8,
      evalPeriod
    );
  }, [
    \audio,
    StaticSpec.new(0.01, 100, \exponential, nil, 1)
  ], \audioEffect
);

