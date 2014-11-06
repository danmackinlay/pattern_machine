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
Server.default = ~server = s = Dan.serverboot(\local, \builtin);
p=PSSamplingStrip.new(0);CmdPeriod.doOnce({ p.free;});
p.group;
p.sourcegroup;
p.fxgroup;
p.jacksynth
p.phasebus.index;
p.recsynth
p.inputgainsynth;
p.otherstuff2free;
CmdPeriod
Buffer.new(
	s.makeBundle(0.0, {l=Bus.control(s,1)});
l