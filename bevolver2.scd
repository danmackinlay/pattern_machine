(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~globalOuts = Bus.new(\audio, 0, 2);
~internalBus = Bus.audio(numChannels: 1);
~eightHundred = Patch({SinOsc.ar(800)}).play(bus: ~internalBus);
//~genosynth = Genosynth.new;
//~genosynth.voxGroup;
~genosynth = Genosynth.new("phenosynth.vox.default", [], "phenosynth.listeners.conv_comparator", [~eightHundred.bus], ~eightHundred.group, ~globalOuts);
~biome = PhenosynthBiome.new(~genosynth, tickPeriod:1);
~biome.play;
~plot= PhenosynthBiomeFitnessPlot(~biome);
~biome.fitnesses.plot;
~biome.population[3].asVals;
instr.specs[4].args;
~biome.fitness.percentile(0.75);
~suspect=~biome.population[10]; 
//~biome.popIndividuals([0,3,4]);
~suspect.voxPatch.bus.scope;
~suspect.fitness;
~suspect.voxPatch.gui;
~suspect.reportingListenerPatch.bus.scope;
~suspect.reportingListenerPatch.gui;
~biome.popIndividual;
~biome.free;
~phenosynth=~genosynth.spawn;
~phenosynth.play;
~phenosynth.fitness;
~phenosynth.reportingListenerPatch.gui;
)
Instr.loadAll;
ControlSpec

Routine