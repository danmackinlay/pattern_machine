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
