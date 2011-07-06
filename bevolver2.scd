(
~genosynth = Genosynth.new;
~phenosynth=~genosynth.spawn;
//~phenosynth=~genosynth.spawnNaked;
~phenosynth.play;
~phenosynth.fitness;
~phenosynth.reportingListenerPatch.gui;
ControlSpec
)

(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~globalOuts = Bus.new(\audio, 0, 2);
~internalBus = Bus.audio(numChannels: 1);
~fivehundred = Patch({SinOsc.ar(800)}).play(bus: ~internalBus);
//~genosynth = Genosynth.new;
//~genosynth.voxGroup;
~genosynth = Genosynth.new("phenosynth.vox.default", [], "phenosynth.listeners.conv_comparator", [~fivehundred.bus], ~fivehundred.group, ~globalOuts);
~phenosynth=~genosynth.spawn;
~phenosynth.play;
~phenosynth.reportingListenerPatch.gui;
//~phenosynth=~genosynth.spawnNaked;
~phenosynth.age;
~phenosynth.fitness;
~phenosynth.triggers;
~phenosynth.chromosome_;
~phenosynth.reportingListenerPatch;
~phenosynth.listeningInstr;
//~phenosynth.voxPatch.play;
~phenosynth2.reportingListenerPatch.gui;
~phenosynth2=~genosynth.spawn;
~phenosynth2.play;
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
Instr.loadAll;
Instr.new("phenosynth.vox.default");
Quarks;
