Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~patch = Patch("phenosynth.defaultinstr", [~sample, { Trig1.kr(Dust.kr(1),0.2); };]).play.gui;
