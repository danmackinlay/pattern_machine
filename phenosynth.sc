Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should be an inner class.*/
  var <genosynth, instr, <chromosome, chromosomeMap, <triggers, <patch;
  *new {|genosynth, instr, chromosomeMap, triggers, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, instr, chromosomeMap, triggers).init(chromosome);
  }
  init {|chromosome|
    patch = Patch.new(instr);
    this.chromosome_(chromosome);
  }
  chromosome_ {|newChromosome|
    /* do this in a setter to allow param update */
    newChromosome.isNil.if({
      newChromosome = {1.0.rand}.dup(chromosomeMap.size);
    });
    chromosome = newChromosome;
    chromosomeMap.do(
      {|specIdx, chromIdx| [specIdx, chromIdx].dump;
         patch.specAt(specIdx).map(chromosome[chromIdx]);
      }
    );
  }
  play {
    patch.play;
    triggers.do({|item, i| patch.specAt(item).map(1);});
    ^patch;
  }
}