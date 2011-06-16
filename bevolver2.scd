~buffer = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");};
~inst = Instr.at("phenosynth.defaultinstr");
~patch = Patch("phenosynth.defaultinstr", ~buffer);