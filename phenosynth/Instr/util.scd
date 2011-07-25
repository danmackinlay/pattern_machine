//pipe an input to the output for bus listening.
Instr(
  "phenosynth.thru",
  {|in|
    in;
  },
  [\audio],
  \audio
);