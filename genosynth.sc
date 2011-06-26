/*
TODO:

* Analyse outputs using UGen:onTrig
* Handle "free controls", values that are passed in live by the user.
* work out a better way to handle non-chromosome'd arguments. right now I
  handle, e.g. SampleSpecs by passing in a defaults array, and triggers by
  introspecting a trigger array. But this is feels ugly compared to wrapping
  an Instr in a function and specifying the missing arguments by lexical
  closure. At the least I could provide lists of specs for each of the
  evolved, free, fixed and trigger parameters, and provide th usual accessors
  to each.
* user EnvelopedPlayer to make this release nicely instead of Triggers.
* Use PlayerMixer to make this fly - or .patchOut?
* Make a LiveGenoSynth to manage a running population. (probably not, that
  should be left to GA infrastructure)
* allow custom evolvability mappings and starting chromosome.
* I've just noticed that MCLD has been facing the same problem and made
  classes similar in spirit to mine, as regards selecting the phenotypes
  rather than genotypes, as the NLTK does:
  http://swiki.hfbk-hamburg.de:8888/MusicTechnology/778

*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr. You would have one of
  these for each population, as a rule.*/
  var <instr, <defaults, <chromosomeMap, <triggers, <>phenoClass;
  classvar <defaultInstr, <defaultPhenoClass;
  *initClass {
    Class.initClassTree(Phenosynth);
    defaultPhenoClass = Phenosynth;
    StartUp.add({ Genosynth.loadDefaultInstr });
  }
  *loadDefaultInstr {
    defaultInstr = Instr.new(
      "genosynth.defaultinstr",
      {|gate = 1,
        time = 1, //envelope scale factor - fit fitness functions to this?
        pitch = 440.0,
        ffreq = 600.0,    
        rq = 0.5|
        var env;
        env = EnvGen.kr(
          Env.asr(time/2, 1, time/2, 'linear'),
          gate: gate//,
          //doneAction: 2
        );
        Resonz.ar(
          Saw.ar(pitch),
          ffreq,   //cutoff
          rq       //inverse bandwidth
        )*env;
      }, #[
        \gate,
        [0.01, 100, \exponential],
        \ffreq,
        \ffreq,
        [0.001, 2, \exponential]
      ] //, \audio
    );
    Instr.new(
      "genosynth.graindrone",
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
    phenoClass = phenoClass ? this.class.defaultPhenoClass;
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
    ^phenoClass.new(this, instr, defaults, chromosomeMap, triggers);
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

GenoSynthListenerFactory {
  /* makes wrapped PhenoSynths attached to listener instrs. This could maybe
  be a subclass of Phenosynth. But probably not. It might even be replaceable
  by a simple factory function.*/
  var <listeningInstrFactory, <outBus, <voxGroup, <listenerGroup;
  classvar <defaultListeningInstr;
  *initClass {
    StartUp.add({ GenoSynthListenerFactory.loadDefaultListener });
  }
  *loadDefaultListener {
    /* the default listener is a toy function to do a convolution with a 500Hz
       and evaluate similarity, with no optimisation.*/
    defaultListeningInstr = Instr.new(
      "genosynth.defaultlistener",
      {|in, evalPeriod = 0|
        var fitness, riseTime, fallTime;
        riseTime = evalPeriod/8;
        fallTime = evalPeriod;
        fitness = LagUD.kr(
          Convolution.ar(in, SinOsc.ar(500), 1024, 0.5).abs,
          riseTime,
          fallTime
        );
        SendTrig.kr(LFPulse.kr((evalPeriod.reciprocal)/2),0,fitness); /*FASTER
                                    than evalPeriod to reduce timing jitter
                                    noise between server and client*/
      }, #[
        \audio,
        [0.01, 100, \exponential]
      ], \audioEffect
    );
  }
  *new { |listeningInstrFactory, outBus| //where listeningInstr could be a factory?
    ^super.newCopyArgs(listeningInstrFactory, outBus).init;
  }
  init {
    listeningInstrFactory = listeningInstrFactory ? {|phenosynth|
      ^Instr("genosynth.defaultlistener");
    };
    voxGroup = Group.new;
    listenerGroup = Group.after(voxGroup);
  }
  spawn { |phenosynth| 
    ^PhenosynthListener.new(phenosynth, listeningInstrFactory,
      outBus, voxGroup, listenerGroup);
  }
}

PhenosynthListener  {
  /* wraps a phenosynth and a fitness function to apply to the synth's output*/
  var <phenosynth, <outBus, voxGroup, listenerGroup;
  var <listener;
  *new {|phenosynth, listenerFactory, outBus, voxGroup, listenerGroup|
    ^super.newCopyArgs(phenosynth, outBus,
      voxGroup, listenerGroup).init(listenerFactory);
  }
  init {|listenerFactory|
    phenosynth.patch.play(group: voxGroup, bus: outBus);
    listener = listenerFactory(phenosynth).play(group: listenerGroup);
    phenosynth.patch.patchOut.connectTo(listener.patchIn);
  }
}