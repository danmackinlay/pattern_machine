Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface */
  var synthdef, <chromosome;
  classvar <defaultInstr;
  *initClass {
    StartUp.add({ Phenosynth.loadDefaultInstr })
  }
  *loadDefaultInstr {
    defaultInstr = Instr(
      "phenosynth.defaultinstr",
      {|sample = 0,
        gate = 1,
        time = 1, //envelope scale factor - fit fitness functions to this.
        pitch = 1,
        pointer = 0.0,
        gain = -12.0,
        pan = 0.0,
        windowSize = 0.1,
        filtFreq = 600.0,    
        rQ = 0.5|
        var env, outMono, outMix;
        env = EnvGen.kr(
          Env.asr(time/2, 1, time/2, 'linear'),
          gate: gate,
          doneAction: 2
        );
        outMono = Resonz.ar(
          Warp1.ar(
            1,      // num channels (Class docs claim only mono works)
            sample,    // buffer
            pointer,    // start pos
            pitch,      // pitch shift
            windowSize,  // window size (sec?)
            -1,      // envbufnum (-1=Hanning)
            4,        // overlap
            0.1,      // rand ratio
            2,        // interp (2=linear)
            gain.dbamp  // mul
          ),
          filtFreq,
          rQ
        );
        outMix = Pan2.ar(
          in: outMono,  // in
          pos: pan,    // field pos
          level: env    // level
        );
      }, #[], \audio
    );
  }
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