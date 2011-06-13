Phenosynth {
  /* wraps an Inst with a nice Spec-based chromosome interface */
  var synthdef, <chromosome;
  *new { |synthdef, chromosome| 
    ^super.newCopyArgs(synthdef, chromosome) 
  }
  *getChromosome {|instr|
    ^instr.specs.size;
  }
}