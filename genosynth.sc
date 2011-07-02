/*
TODO:

* make ListeningPhenoSynth.play work.
* move patch creation into a "play" or "go" method.
* Handle "free controls", values that are passed in live by the user. (esp for
  triggers)
  
  * alter chromosome if Specs are changed through UI or any other means, using
    all that Dependent business
    
* work out a better way to handle non-chromosome'd arguments. right now I
  handle, e.g. SampleSpecs by passing in a defaults array, and triggers by
  introspecting a trigger array. But this is feels ugly compared to wrapping
  an Instr in a function and specifying the missing arguments by lexical
  closure. At the least I could provide lists of specs for each of the
  evolved, free, fixed and trigger parameters, and provide the usual accessors
  to each. (Compare static, fixed and control specs)
* user EnvelopedPlayer to make this release nicely instead of Triggers.
* Use PlayerMixer to make this fly - or .patchOut?
* Make a LiveGenoSynth to manage a running population. (probably not, that
  should be left to GA infrastructure)
* allow custom evolvability mappings and starting chromosome.
* I've just noticed that MCLD has been facing the same problem and made
  classes similar in spirit to mine, as regards selecting the phenotypes
  rather than genotypes, as the NLTK does:
  http://swiki.hfbk-hamburg.de:8888/MusicTechnology/778
* put these guys in the correct groups
* do free/cleanup logic
* give fitness more accumulatey flavour using Integrator

CREDITS:
Thanks to Martin Marier and Crucial Felix for tips that make this go, and
James Nichols for the peer pressure to do it.

HOWTO proceed:
--  http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Instr-Patch-and-some-machine-listening-tp6519284p6522975.html --

        I've been looking at doing some machine listening in SC, using Instr's
        sweet, sweet reflection capabilities to listen to the output of a
        patch and classify it at the same time as I play it - that is, I would
        like to make the output of the Patch be audible both through my
        soundcard outputs, and to the input of the Instr that will do the
        machine listening. However, I can't get my head around how to patch
        that together. I get either stubborn silence through my speakers, or
        errors from my code. I'd really appreciate some guidance from the
        patching ninjas on this one.
        
         I'd like to take a Patch instance (call it "voxPatch") and an Instr
        which analyses it (call it "listener") outputting a signal to
        indicate, e.g. how well its inputs correlate with a specified signal.
        I'd like to get that signal back to the client so I can tweak my synth
        parameters based upon its value. I don't want to hear the output of
        "listener", which might be mostly DC - but I do want to poll its value
        on the client side, and i do want to hear the output of voxPatch, on
        some bus or other.

    the kr patch wouldn't be audible anyway, it plays on its own kr bus...
    
    you can use patch.bus to get its bus
    
    and I think you can pass patch.bus to another patch as an input arg
    
    the difference being that if you passed the patch to another patch then
    it would be a child
    
    but if you passed just its bus then it just reads from the bus and you
    need to start the patch separately.

*/

Genosynth {
  /* A factory for Phenosynths wrapping a given Instr. You would have one of
  these for each population, as a rule.*/
  var <instr, <defaults, <chromosomeMap, <triggers, <listeningInstr, <evalPeriod;
  classvar <defaultInstr,<defaultListeningInstr;
  *initClass {
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
    defaultListeningInstr = Instr.new(
      "genosynth.defaultlistener",
      {|in, evalPeriod = 1|
        LagUD.ar(
          Convolution.ar(in, SinOsc.ar(500), 1024, 0.5).abs,
          evalPeriod/8,
          evalPeriod
        );
      }, [
        \audio,
        StaticSpec.new(0.01, 100, \exponential, nil, 1)
      ], \audioEffect
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
  *new { |name="genosynth.defaultinstr", defaults=#[]|
    ^super.newCopyArgs(name.asInstr, defaults).init;
  }
  init {
    chromosomeMap = this.class.getChromosomeMap(instr);
    // pad defaults out to equal number of args
    defaults = defaults.extend(instr.specs.size, nil);
    triggers = this.class.getTriggers(instr);
    /*We give default values to any triggers without a one, or they
    get saddled with an inconvenient BeatClockPlayer*/
    triggers.do({|trigIndex, i| (defaults[trigIndex].isNil).if(
      {defaults[trigIndex] = 1.0;})
    });
  }
  spawnNaked { |chromosome|
    //just return the phenosynth itsdlef, without listeners
    ^Phenosynth.new(this, instr, defaults, chromosomeMap, triggers, chromosome);
  }
  spawn { |chromosome|
    //return a listened phenosynth
    ^ListeningPhenosynth.new(this, instr, defaults, chromosomeMap, triggers, listeningInstr, evalPeriod, chromosome);
  }
  *getChromosomeMap {|newInstr|
    /*use this to work out how to map the chromosome array to synth values,
    ignoring any fixed values, sampleSpecs, or any other kind of
    NonControlSpec
    TODO: Work out how to do this with duck typing.*/
    ^newInstr.specs.indicesSuchThat({|item, i|
      (item.isKindOf(NonControlSpec).not);});
  }
  *getTriggers {|newInstr|
    /*The other input type we might care about is a trigger. I don't know why
    you'd want more than one, but it's more symmetrical if we assume a list,
    so ...*/
    ^newInstr.specs.indicesSuchThat({|item, i|
      item.isKindOf(TrigSpec)});
  }
}

Phenosynth {
  /* wraps an Instr with a nice Spec-based chromosome interface. This should
  be an inner class of GenoSynth, really, but SC doesn't namespace in that
  way.*/
  var <genosynth, <instr, <defaults, <chromosomeMap, <triggers, <voxPatch;
  var <chromosome = nil;
  *new {|genosynth, instr, defaults, chromosomeMap, triggers, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, instr, defaults, chromosomeMap, triggers).init(chromosome);
  }
  init {|chromosome|
    this.createPatch;
    this.chromosome_(chromosome);
  }
  createPatch {
    voxPatch = Patch.new(instr, defaults);
  }
  chromosome_ {|newChromosome|
    /* do this in a setter to allow param update */
    newChromosome.isNil.if({
      newChromosome = {1.0.rand}.dup(chromosomeMap.size);
    });
    chromosome = newChromosome;
    chromosomeMap.do(
      {|specIdx, chromIdx|
        voxPatch.specAt(specIdx).map(chromosome[chromIdx]);
      }
    );
  }
  play {
    voxPatch.play;
    ["triggers", triggers].postln;
    triggers.do({|item, i| voxPatch.set(item).map(1);});
  }
}

ListeningPhenosynth : Phenosynth {
  var <listeningInstr;
  var <evalPeriod = 1;
  var <fitness = 0;
  var <age = 0;
  var <reportingListenerPatch, <reportingListenerInstr, <listener;
  *new {|genosynth, instr, defaults, chromosomeMap, triggers, listeningInstr, evalPeriod=1, chromosome|
    //This should only be called through the parent Genosynth's spawn method
    ^super.newCopyArgs(genosynth, instr, defaults, chromosomeMap, triggers).init(chromosome, listeningInstr, evalPeriod);
  }
  init {|chromosome, listeningInstr_, evalPeriod_|
    listeningInstr = listeningInstr_ ? Genosynth.defaultListeningInstr;
    evalPeriod = evalPeriod_ ? 1.0;
    super.init(chromosome);
  }
  createPatch {
    super.createPatch;
    listener = Patch(listeningInstr, [
        voxPatch,
        evalPeriod
      ]
    );
    reportingListenerInstr = ReportingListenerFactory.make({
      |time, value|
      fitness = value;
      age = age + 1;
      //this.dump;
      //["updating correlation", this.hash, time, value, age].postln;
    });
    reportingListenerPatch = Patch(
      reportingListenerInstr, [
        listener, evalPeriod
      ]
    );
  }
  play {
    /*play reportingListener - I'd like to make it on a private bus, or no bus
    at all, but don't yet understand how to make that server-agnostic.*/
    super.play;
    reportingListenerPatch.play;
  }
}

ReportingListenerFactory {
  /*Instrs like having names, so we make some on demand to keep things clean.
  TODO: I'm not totally sure if this is neccessary, and should check that
  after the current deadline crunch.*/
  classvar counter = 0;
  *make {|onTrigFn, evalPeriod=1|
    /*takes a function of the form {|time, value| foo} */
    var newInstr;
    newInstr = Instr(
      "genosynth.reportingListener.volatile." ++ counter.asString,
      {|in, evalPeriod=1|
        LFPulse.kr((evalPeriod.reciprocal)/2).onTrig(onTrigFn, in);
        // actually just be quiet please
        Silent.ar
      },
      [\audio], \audio
    );
    counter = counter+1;
    ^newInstr;
  }
}
