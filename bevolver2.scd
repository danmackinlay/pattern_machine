(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~instr.specs;
~instr.class;
~genosynth = Genosynth(~instr);
//~genosynth = Genosynth.new("genosynth.defaultinstr");
~phenosynth=~genosynth.spawn;
~phenosynth.patch.play;
~patch = ~phenosynth.play.dump;
~phenosynth.patch.gui;
~patch.gui;
)
~genosynth.insp;
Genosynth.findMethod('specs');
Genosynth.dumpInterface;
Genosynth.dumpFullInterface;
Genosynth.defaultInstr;
Genosynth.spawn;
~patch = Patch("genosynth.defaultinstr", [~sample, 1, 10]).play.gui;
