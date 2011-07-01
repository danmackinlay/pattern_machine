(
~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~genosynth = Genosynth(~instr, []);
~phenosynth=~genosynth.spawn;
~phenosynth.voxPatch.bus.play;
~phenosynth.reportingListenerPatch.play;
~phenosynth.chromosome;
~phenosynth=~genosynth.spawnNaked;
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
