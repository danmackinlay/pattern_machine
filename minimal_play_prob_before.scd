/* my minimal reproduction of the problems with getting the signal flow right*/
(
    var globalOuts;
    var listeningInstr, voxPatch, listener, reportingListenerPatch;
    var voxGroup, listenerGroup;
    var evalPeriod=1;
    globalOuts = Bus.new(\audio, 0, 1);//my soundcard outs
    ~age = 0; //tracks voxPatch's lifetime
    ~correlation = 0; //holds voxPatch's correlatedness

    //make groups in the hope of getting execution order right
    voxGroup = Group.new;
    listenerGroup = Group.after(voxGroup);

    //define instr ins
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
