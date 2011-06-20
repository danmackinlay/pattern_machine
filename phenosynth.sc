Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should be an inner class.*/
  var <genosynth, <instr, <chromosome, chromosomeMap;
  *new {|genosynth, instr, chromosomeMap, chromosomeSize, newChromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.new.init(
      genosynth, instr, chromosomeMap, chromosomeSize, newChromosome
    );
  }
  init {|genosynth, instr, newChromosomeMap, newChromosome|
    genosynth = genosynth;
    instr = instr;
    chromosomeMap = chromosomeMap;
    this.chromosome_(newChromosome);
  }
  chromosome_ {|newChromosome|
    chromosome = newChromosome;
  }
  asPatch {
    
  }
}