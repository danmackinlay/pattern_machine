fork {
	~samples = PSSamples.new(basePath: PS.scsamplepath, dur: ~sampleDur));
	~samples.initFromDict((
		siren: [
			"22370__druidus__Civil_Defence_Siren.wav",
			"24347__fonogeno__Police_sirens-short.wav",
			//"30476__LG__Dutch_air_raid_warning_02.wav",
			"43807__daveincamas__WW2AirplaneFlyover.wav",
		]
	));
	s.sync;
};
Server.default = Dan.serverboot(\local, \builtin);
p=PSSamplingStrip.new(0);CmdPeriod.doOnce({ p.free;});
p=PSSamplingStrip.new(1, Group.new);CmdPeriod.doOnce({ p.free;});
p.group;
p.sourcegroup;
p.fxgroup;
p.jacksynth;
p.recsynth;
p.phasebus.index;
p.recsynth.nodeID
p.inputgainsynth;
p.otherstuff2free;
Server.default.window
s.tree
Server.default.nodes