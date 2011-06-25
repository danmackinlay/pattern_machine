/*
TODO:

* Analyse outputs.
* work out a better way to handle non-chromosome'd arguments. right now I
  handle, e.g. SampleSpecs by passing in a defaults array, and triggers by
  introspecting a trigger array. But this is feels ugly comapred to wrapping
  an Instr in a function and specifying the missing arguments by lexical
  closure.
* user EnvelopedPlayer to make this release nicely
* Use PlayerMixer to make this fly - or .patchOut?
* Make a LiveGenoSynth to manage a running population. (probably not, that
  should be left to GA infrastructure)
* allow custom evolvability mappings and starting chromosome.
* I've just noticed that MCLD has been facing the same problem and made
  classes imilar in spirit to mine:
  http://swiki.hfbk-hamburg.de:8888/MusicTechnology/778

*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr */
  var <instr, <defaults, <chromosomeMap, <triggers;
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
        gain = 0.5,
        pan = 0.0,
        windowSize = 0.1,
        ffreq = 600.0,    
        rq = 0.5|
        var env, outMono, outMix;
        var bufnum = sample.bufnumIr;
        sample.load();
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
  init {
    chromosomeMap = this.class.getChromosomeMap(instr);
    // pad defaults out to equal number of args
    defaults = defaults.extend(instr.specs.size, nil);
    triggers = this.class.getTriggers(instr);
    //We give any triggers without a default value of zero, or they get
    //saddled with an inconvenient BeatClockPlayer
    triggers.do({|trigIndex, i| (defaults[trigIndex].isNil).if(
      {defaults[trigIndex] = 1.0;})
    });
  }
  spawn { |chromosome| 
    ^Phenosynth.new(this, instr, defaults, chromosomeMap, triggers);
  }
  *getChromosomeMap {|newInstr|
    /*use this to work out how to map the chromosome array to synth values,
    ignoring any fixed values, sampleSpecs, or any other kind of
    NonControlSpec
    TODO: Work out how to do this with duck typing.*/
    ^all {: i, i<-(0..newInstr.specs.size),
      newInstr.specs[i].isKindOf(NonControlSpec).not};
  }
  *getTriggers {|newInstr|
    /*The other input type we might care about is a trigger. I don't know why
    you'd want more than one, but it's more symmetrical if we assume a list,
    so ...*/
    ^all {: i, i<-(0..newInstr.specs.size),
      newInstr.specs[i].isKindOf(TrigSpec)};
  }
  specs {
    ^instr.specs;
  }
}

Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should
  be an inner class of GenoSynth, really, but SC doesn't namespace in that
  way.*/
  var <genosynth, <instr, <defaults, <chromosome, <chromosomeMap, <triggers, <patch;
  *new {|genosynth, instr, defaults, chromosomeMap, triggers, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, instr, defaults, chromosomeMap, triggers).init(chromosome);
  }
  init {|chromosome|
    patch = Patch.new(instr, defaults);
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

ListeningAgent {
  /* wraps a phenosynth and a fitness function to apply to the synth's output*/
  
  
}