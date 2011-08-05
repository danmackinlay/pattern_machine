PSPhenome {
  var <chromosome;
  var <>fitness=0;
  var <age;
  
  *new{|chromosome|
    ^super.new.init(chromosome);
  }
  init {|chromosome|
    this.chromosome = chromosome;
  }
  chromosome_ {|newChromosome|
    chromosome = newChromosome;
  }
  play {|out|
    NotYetImplementedError.new.throw;
  }
}

PSSynthDefPhenome : PSPhenome{
  //A phenome mapping a chromosome to the inputs of a Synth
  classvar <synthdef = \ps_reson_saw;
  classvar <genomeSize = 3;
  classvar <map;
  var <mappedArgs;
  *initClass {
    StartUp.add {
      this.setUpSynthDefs;
    }
  }
  *newRandom {
    var newChromosome = {1.0.rand;}.dup(genomeSize);
    ^this.new(newChromosome);
  }
  *setUpSynthDefs {
    SynthDef.new(
      \ps_reson_saw,
      {|out=0, gate=0, t_reset=0, pitch, ffreq, rq|
        var env;
        var time = 1;
        env = EnvGen.kr(
          Env.asr(time/2, 1, time/2, 'linear'),
          gate: gate//,
          //doneAction: 2
        );
        Out.ar(out, Resonz.ar(
          Saw.ar(pitch),
            ffreq,   //cutoff
            rq       //inverse bandwidth
          )*env
        );
      }
    ).add;
    map = (
      \pitch: \midfreq.asSpec,
      \ffreq: \midfreq.asSpec,
      \rq: \rq.asSpec
    );
  }
  play {|out, group|
    mappedArgs = this.chromosomeAsSynthArgs;
    ^Synth.new(
      this.class.synthdef,
      args: [\out, out, \gate, 1] ++ mappedArgs,
      target: group
    )
  }
  chromosomeAsSynthArgs {
/*    This list comprehension is not especially clear now, is it?
    What it does is zip together the key, map spec and value 
    lists into one, then iterates over this, returning mapped values
    associated with their keys as a synth expects*/
    ^(all {: [keySpecVal[0], keySpecVal[1].map(keySpecVal[2])],
      keySpecVal <- (this.class.map.asSortedArray +++ chromosome)
    }).flat;
  }
}
  
