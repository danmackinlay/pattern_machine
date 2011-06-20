Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should be an inner class.*/
  var <genosynth, <instr, <chromosome, chromosomeMask, chromosomeSize;
  *new {|genosynth, instr, chromosomeMask, chromosomeSize, newChromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.new.init(
      genosynth, instr, chromosomeMask, chromosomeSize, newChromosome
    );
  }
  init {|genosynth, instr, chromosomeMask, chromosomeSize, newChromosome|
    genosynth = genosynth;
    instr = instr;
    chromosomeMask = chromosomeMask;
    chromosomeSize = chromosomeSize;
    this.chromosome_(newChromosome);
  }
  chromosome_ {|newChromosome|
    chromosome = newChromosome;
  }
}