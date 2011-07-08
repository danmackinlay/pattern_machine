Instr.new(
  "phenosynth.vox.default",
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
    [0.1, 10.0, \exponential],
    [40.0, 10000.0, \exponential],
    [40.0, 10000.0, \exponential],
    [0.01, 1.0, \exponential]
  ] //, \audio
);
Instr.new(
  "phenosynth.vox.graindrone",
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
