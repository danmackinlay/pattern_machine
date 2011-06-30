/*Felix's illustrated guide to everything i did wrong*/

/*
	you are actually playing voxPatch twice.
	once on its own and once inside listener.
	so its already been given a bus
        and thus the 2nd time doesn't work

	you can easily listen in on the bus that voxPatch is playing on:
	voxPatch.bus.play;
	
	private: true is an arg to prepareToBundle, not to play as I said yesterday. sorry
	
*/
(
    var globalOuts;
    var listeningInstr, voxPatch, listener, reportingListenerPatch, reportingListenerInstr;
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

     // this is how I noticed that it was playing twice !       
        pitch.poll;
        
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
    
    reportingListenerInstr = RecordingListenerFactory.make({
      |time, value|
      ~correlation = value;
      ~age = ~age + 1;
      ["updating correlation", time, value, ~age].postln;
    });

    //Wrap the listener in an anonymous patch which converts its audio rate out into a
    //scalar value on the client through the magic of onTrig.

    reportingListenerPatch = Patch(reportingListenerInstr, [listener, evalPeriod]);
    // this contains listener
    // which contains voxPatch
    // so gui the top level and you will see the hierarchy
    reportingListenerPatch.gui;
    // play it, but don't listen to it (though its silent anyway) so send it to a private bus
    reportingListenerPatch.play(bus: Bus.audio(s,2) );
    
    // and just listen to the bus of the voxPatch
     voxPatch.bus.play;
    
)

