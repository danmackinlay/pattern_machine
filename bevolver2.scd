Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~patch = Patch("phenosynth.defaultinstr", [~sample, 1, 10, 1, 1, 0.5, 0]).play.gui;
