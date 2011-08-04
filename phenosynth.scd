(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~globalOuts = Bus.new(\audio, 0, 2);
~internalBus = Bus.audio(numChannels: 1);
~eightHundred = Patch({SinOsc.ar(800)}).play(bus: ~internalBus);
//~genosynth = Genosynth.new;
//~genosynth.voxGroup;
~genosynth = Genosynth.new("phenosynth.vox.default", [], "phenosynth.judges.fft_soft_comparator", [~eightHundred], ~eightHundred.group, ~globalOuts);
~biome = PhenosynthBiome.new(~genosynth, tickPeriod:1, deathRate:0.1, birthRate: 0.2, birthFitness: 100, deathFitness: 10);
~biome.play;
~biome.population[0].voxPatch.defName
~biome.population[0].voxPatch.server;

~plot= PhenosynthBiomeFitnessPlot(~biome);
~biome.fitnesses.plot;
~biome.population[0].asVals;
~suspect=~biome.population[10]; 
//~biome.popIndividuals([0,3,4]);
//~suspect.voxPatch.bus.scope;
~suspect.fitness;
~suspect.voxPatch.gui;
~suspect.reportingListenerPatch.bus.scope;
~suspect.reportingListenerPatch.gui;
~biome.popIndividual;
~biome.free;
Instr("fasdasd")

(
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~globalOuts = Bus.new(\audio, 0, 2);
~internalBus = Bus.audio(numChannels: 1);
~eightHundred = Patch({SinOsc.ar(800)}).play(bus: ~internalBus);
//~genosynth = Genosynth.new;
//~genosynth.voxGroup;
~genosynth = Genosynth.new("phenosynth.vox.default", [], "phenosynth.judges.fft_soft_comparator", [~eightHundred], ~eightHundred.group, ~globalOuts);
~phenosynth=~genosynth.spawn;
~phenosynth.play;
~phenosynth.fitness;
~phenosynth.reportingListenerPatch.gui;
~genosynth.free;
)
Instr.loadAll;
~p1=~genosynth.spawn;
~p2=~genosynth.spawn;
~p2.free;
~genosynth.all;

(
s=Server.default;
~control = PSListenSynthController.new(s);
~control.playGroup;
~control.server;
~control.outBus;
~ind = PSSynthDefPhenome([0.5, 0.5, 0.5]);
~control.playIndividual(~ind);
)