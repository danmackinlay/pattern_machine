(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~globalOuts = Bus.new(\audio, 0, 2);
~internalBus = Bus.audio(numChannels: 1);
~fivehundred = Patch({SinOsc.ar(800)}).play(bus: ~internalBus);
//~genosynth = Genosynth.new;
//~genosynth.voxGroup;
~genosynth = Genosynth.new("phenosynth.vox.default", [], "phenosynth.listeners.conv_comparator", [~fivehundred.bus], ~fivehundred.group, ~globalOuts);
~biome = PhenosynthBiome.new(~genosynth);
~biome.play;
~biome.free;

~phenosynth=~genosynth.spawn;
~phenosynth.play;
~phenosynth.fitness;
~phenosynth.reportingListenerPatch.gui;
)
Instr.loadAll;
