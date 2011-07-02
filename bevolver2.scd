
(
~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~genosynth = Genosynth.new(~instr, []);
~genosynth = Genosynth.new;
~genosynth.instr.specs;
~genosynth.triggers;
~phenosynth=~genosynth.spawn;
~phenosynth.age;
~phenosynth.fitness;
//~phenosynth.voxPatch.play;
~phenosynth.play;
~phenosynth.reportingListenerPatch.play;
~phenosynth2=~genosynth.spawn;
~phenosynth2.voxPatch.play;
~phenosynth2.reportingListenerPatch.play;
~phenosynth2.fitness;
~phenosynth2.chromosome;
~phenosynth2.age;
~phenosynth.dump;
~phenosynth.class.dumpInterface;
Phenosynth.dumpInterface;
~phenosynth=~genosynth.spawnNaked;
~phenosynth.reportingListenerPatch.gui;
~phenosynth2.reportingListenerPatch.gui;
)