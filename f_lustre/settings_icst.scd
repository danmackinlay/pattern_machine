s.makeGui;
~fl.replaceSound.value("note_sweep.aif");
~fl.replaceSound.value("draingigm.wav");
~fl.replaceSound.value("chimegongfrenzy.aif");

//TODO: deal with spurious touches; they look like [ starting, 200, 1.0828125476837, 0.87638884782791, 0, 0, 0.27070313692093, 3864.5417805264, -0.45859372615814 ]
//TODO: frequency mapping ins vertically inverted.

(
var server,options, fl;
~fl = "not initialised";
server=Server.default;
options = ServerOptions.new;
options.device = "Fireface 800 (AA)";
server.serverRunning.if({
		server.reboot({server.options_(options)});
	}, {
		server.options_(options);
		server.boot;
});
server.waitForBoot(fork {
	fl=FLustre.new(workingDir: "/Users/icst/Desktop/Dan_FLustre", xMax:4, pixWidth: 1280*4, pixHeight:720, nRingSpeakers: 8, nSpeakerRings:2, firstOutputBus: 0, debugLvl: -1);
	server.sync;
	fl.initServer;
	~fl = fl;
});
)
NetAddr.new("224.0.0.1", 64000).sendMsg("/trackerMaster/requestTuiostream", 3335);

~fl.soundBuf.play;