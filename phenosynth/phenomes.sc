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
  *initClass {
    Startup.add {
      this.setUpSynthDefs;
    }
  }
  setUpSynthDefs {
    SynthDef.writeOnce(
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
    );
    map = (
      \pitch: \midfreq.asSpec,
      \ffreq: \midfreq.asSpec,
      \rq: \rq.asSpec
    );
  }
  play {|out, group|
    var mappedArgs;
    mappedArgs = this.chromosomeAsSynthArgs;
    ^Synth.new(
      this.class.synthdef,
      args: [\out, out] ++ mappedArgs,
      target: group
    )
  }
  chromosomeAsSynthArgs {
    ^all {: [keySpec[0], keySpec[1].map(val)],
      keySpec <- map.asSortedArray,
      val <- chromosome
    };
  }
}
  
