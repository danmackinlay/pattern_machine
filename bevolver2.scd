(
~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~instr.specs;
~instr.class;
~genosynth = Genosynth(~instr, []);
//~genosynth = Genosynth.new("genosynth.defaultinstr");
~phenosynth=~genosynth.spawn;
~phenosynthListenerFactory=PhenosynthListenerFactory(evalPeriod:1, outBus:~globalOuts);
~phenosynthListenerFactory.listeningInstrFactory.value;
~phenosynthListener = ~phenosynthListenerFactory.spawn(~phenosynth);
~phenosynthListener.fitness;
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

~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~instr.specs;
~instr.class;
~genosynth = Genosynth(~instr, []);
//~genosynth = Genosynth.new("genosynth.defaultinstr");
~phenosynth=~genosynth.spawn;
~voxGroup = Group.new;
~listenerGroup = Group.after(~voxGroup);
~age = 0;
~fitness = 0;
~evalPeriod = 1;
~listeningInstrFactory	=  {|phenosynth, evalPeriod| Instr("genosynth.defaultlistener");};
["PhenosynthListener init", ~listeningInstrFactory, ~phenosynth, ~evalPeriod].postln;
~listeningInstrFactory.asCompileString.postln;
~phenosynth.patch.play(group: ~voxGroup);
//~listeningInstrFactory.value(~phenosynth, ~evalPeriod);
//Mr faily
~listener = Patch(~listeningInstrFactory.value(~phenosynth, ~evalPeriod), [~phenosynth.patch, ~evalPeriod]);
~phenosynth.patch.patchOut.connectTo(
  ~listener).play(group: ~listenerGroup);
~pimpedOutListener = Patch({|in, evalPeriod=1|
  LFPulse.kr((evalPeriod.reciprocal)/2).onTrig(
    {
      |time, value|
      ~fitness = value;
      ~age = ~age + 1;
      ["updating fitness", time, value, ~age].postln;
    }, in
  );
}, [~listener, ~evalPeriod]); //Now, where does the output of this guy go?
~pimpedOutListener.play(group: ~listenerGroup);
~listener.class.dumpFullInterface;