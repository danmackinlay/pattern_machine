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
~phenosynth.fitness;
l=List.fill(5, {~genosynth.spawn;});
l.do({|i| i.play;});
l.do({|i| i.chromosome_; i.chromosome.postln;});
l[0].reportingListenerPatch.gui;
l[1].reportingListenerPatch.gui;
l.remove(l[2]);
l.collect({|i| i.reportingListenerPatch.postln;});
ReportingListenerFactory.counter;
l.collect({|i| i.fitness;});
~phenosynth.reportingListenerPatch.gui;
)
Instr.loadAll;
3.isKindOf(SimpleNumber)