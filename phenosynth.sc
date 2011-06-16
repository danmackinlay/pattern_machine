Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface */
  var synthdef, <chromosome;
  *new { |instr, chromosome| 
    ^super.newCopyArgs(instr, chromosome) ;
  }
  chromosome_ { |newChromosome|
    chromosome = newChromosome;
  }
  *getChromosomeSize {|instr|
    ^instr.specs.size;
  }
}