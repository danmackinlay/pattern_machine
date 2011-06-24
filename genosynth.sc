/*
I will want to ignore some Instr params. The way to do this is to look for
instances of subclasses of NonControlSpec. I'd rather do it by generating new instruments by closure.

TODO:

* handle non-chromosome'd arguments. Or can I just wrap them away by defining instruments with the default inputs fixed?

  * see "Fixed Arguments" in the Patch help

* user EnvelopedPlayer to make this release nicely
* Use PlayerMixer to make this fly
* Make a LiveGenoSynth to manage a running population.
* allow custom evolvability mappings and starting chromosome.

*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr */
  var <instr, defaults, <chromosomeMap, <triggers;
  classvar <defaultInstr;
  *initClass {
    StartUp.add({ Genosynth.loadDefaultInstr })
  }
  *loadDefaultInstr {
    defaultInstr = Instr.new(
      "genosynth.defaultinstr",
      {|sample = 0,
        gate = 1,
        time = 1, //envelope scale factor - fit fitness functions to this?
        pitch = 1,
        pointer = 0.0,
        gain = 0,
        pan = 0.0,
        windowSize = 0.1,
        ffreq = 600.0,    
        rq = 0.5|
        var env, outMono, outMix;
        var bufnum = sample.bufnumIr;
        env = EnvGen.kr(
          Env.asr(time/2, 1, time/2, 'linear'),
          gate: gate,
          doneAction: 2
        );
        outMono = Resonz.ar(
          Warp1.ar(
            1,          // num channels (Class docs claim only mono works)
            bufnum,     // buffer
            pointer,    // start pos
            pitch,      // pitch shift
            windowSize, // window size (sec?)
            -1,         // envbufnum (-1=Hanning)
            4,          // overlap
            0.1,        // rand ratio
            2,          // interp (2=linear)
            gain        // mul
          ),
          ffreq,   //cutoff
          rq       //inverse bandwidth
        );
        Pan2.ar(
          in: outMono,  // in
          pos: pan,     // field pos
          level: env    // level, enveloped
        );
      }, #[
        nil,
        \gate,
        [0.01, 100, \exponential],
        \freqScale,
        [0.0, 1.0],
        [0.01, 2, \exponential],
        \pan,
        [0.001, 1, \exponential],
        \ffreq,
        [0.001, 2, \exponential]
      ], \audio
    );
  }
  *new { |name, defaults| 
    ^super.newCopyArgs(name.asInstr, defaults).init;
  }
  init {|newInstr|
    chromosomeMap = this.class.getChromosomeMap(instr);
    triggers = this.class.getTriggers(instr);
  }
  spawn { |chromosome| 
    ^Phenosynth.new(this, instr, defaults, chromosomeMap, triggers);
  }
  *getChromosomeMap {|newInstr|
    //use this to work out how to map the chromosome array to synth values.
    ^all {: i, i<-(0..newInstr.specs.size),
      newInstr.specs[i].isKindOf(NonControlSpec).not};
  }
  *getTriggers {|newInstr|
    //the other input type we might care about is a trigger. I don't know why you'd want more than one, but it's more symmetrical if we assume a list, so ...
    ^all {: i, i<-(0..newInstr.specs.size),
      newInstr.specs[i].isKindOf(TrigSpec)};
  }
  specs {
    ^instr.specs;
  }
}