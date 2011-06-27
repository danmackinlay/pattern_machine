(
~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~instr.specs;
~instr.class;
~genosynth = Genosynth(~instr, []);
~phenosynth=~genosynth.spawn;
~phenosynthListenerFactory=PhenosynthListenerFactory(evalPeriod:1, outBus:~globalOuts);
~phenosynthListener = ~phenosynthListenerFactory.spawn(~phenosynth);
~phenosynthListener.debug;
~phenosynthListener.correlation;
~phenosynthListener.age;
)
//~patch = ~phenosynth.play.dump;
//~phenosynth.patch.patchOut.numChannels;
//~phenosynth.patch.patchIn;
//~phenosynth.patch.numChannels;
~phenosynth.patch.set(\gate, 1);
~genosynth.defaults;
~genosynth.dumpFullInterface;
Genosynth.findMethod('specs');
Genosynth.dumpInterface;
Genosynth.dumpFullInterface;
Genosynth.defaultInstr;
(
    var globalOuts;
    var listeningInstr, voxPatch, listener, reportingListenerPatch;
    var voxGroup, listenerGroup;
    var evalPeriod=1;
    globalOuts = Bus.new(\audio, 0, 1);//my soundcard outs
    ~age = 0; //tracks voxPatch's lifetime
    ~correlation = 0; //holds voxPatch's correlatedness
    
    voxGroup = Group.new;
    listenerGroup = Group.after(voxGroup);
    
    listeningInstr = Instr.new(
      "phonosynth.defaultlistener",
      {|in, evalPeriod = 1|
        //A toy analysis function, which measures similarity between its input
        //and a 500Hz reference sine wave.
        LagUD.ar(
          Convolution.ar(in, SinOsc.ar(500), 1024, 0.5).abs,
          evalPeriod/8,
          evalPeriod
        );
      }, [
        \audio,
        StaticSpec.new(0.01, 100, \exponential, nil, 1)
      ]
    );
    voxPatch = Patch.new(Instr.new(
      "phonosynth.defaultinstr",
      {|pitch = 440.0,
        ffreq = 600.0,    
        rq = 0.5|
        //A toy synth, for testing.
        Resonz.ar(
          Saw.ar(pitch),
          ffreq,   
          rq
        );
      }, #[
        \ffreq,
        \ffreq,
        [0.001, 2, \exponential]
      ]
    ));
    listener = Patch(listeningInstr, [
        voxPatch,
        evalPeriod
      ]
    );
    //Wrap the listener in an anonymous patch which converts its audio rate out into a
    //scalar value on the client through the magic of onTrig.
    reportingListenerPatch = Patch({|in, evalPeriod=1|
      LFPulse.kr((evalPeriod.reciprocal)/2).onTrig(
        {
          |time, value|
          ~correlation = value;
          ~age = ~age + 1;
          ["updating correlation", time, value, ~age].postln;
        }, in
      );
    }, [listener, evalPeriod]); 
    reportingListenerPatch.play(group: listenerGroup);
    listener.play(group: listenerGroup);
    voxPatch.play(group: voxGroup, bus: globalOuts);
    voxPatch.gui;
)
