/*
I will want to ignore some Instr params. The way to do this is to look for
instances of subclasses of NonControlSpec. I need to modify getChromosomeSize
to make this go.
TODO: user EnvelopedPlayer to make this release nicely
Use PlayerMixer to make this fly
Make a LiveGenoSynth to manage a running population.
*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr */
  var <instr;
  var chromosomeMask, chromosomeSize;
  classvar <defaultInstr;
  *initClass {
    StartUp.add({ Genosynth.loadDefaultInstr })
  }
  *loadDefaultInstr {
    defaultInstr = Instr.new(
      "phenosynth.defaultinstr",
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
        sample.load();
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
  *new { |instr| 
    super.new.init(instr);
  }
  init {|instr|
    instr = instr;
    chromosomeSize = this.getChromosomeSize(instr);
  }
  spawn { |chromosome| 
    ^Phenosynth.new(this,
      instr //,
//      chromosomeMask,
//      chromosomeSize,
//      chromosome
    );
  }
  *getChromosomeSize {|instr|
    //use this to work out how long an array to pass in.
    ^instr.specs.size;
  }
  *getChromosomeMask {|instr|
    //use this to work out how to map the chromosome array to synth values.
/*    ^(0..this.getChromosomeSize(instr);*/
  }
  
}