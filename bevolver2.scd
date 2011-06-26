(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~instr.specs;
~instr.class;
~genosynth = Genosynth(~instr, []);
//~genosynth = Genosynth.new("genosynth.defaultinstr");
~phenosynth=~genosynth.spawn;
~phenosynth.patch.play;
~patch = ~phenosynth.play.dump;
~phenosynth.patchOut.dump;
~phenosynth.patch.patchOut;
~phenosynth.patch.patchIn;
~phenosynth.patch.numChannels;
)
~phenosynth.patch.set(\gate, 1);
~genosynth.defaults;
~genosynth.dumpFullInterface;
Genosynth.findMethod('specs');
Genosynth.dumpInterface;
Genosynth.dumpFullInterface;
Genosynth.defaultInstr;
