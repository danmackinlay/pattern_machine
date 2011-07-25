Instr(
  "phenosynth.reporter",
  {|in, evalPeriod=1, phenoID|
    var totalFitness;
    totalFitness = A2K.kr(Mix.ar(in));
    SendTrig.kr(
      LFPulse.kr((evalPeriod.reciprocal)/2),
      phenoID, 
      totalFitness
    );
    Silence.ar;
  },
  [\audio, \noncontrol, \noncontrol],
  \audio
);