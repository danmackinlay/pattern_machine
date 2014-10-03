Dan {
	/*
	 * The following function allows you to choose different combinations of internal and localhost
	 * servers, and internal and motu soundcards. It presumes your local stacked device is called
	 * "internal sound devices"
	Server.default = s = Dan.serverboot(\local, \builtin);
	Server.default = s = Dan.serverboot(\local, \rme);
	Server.default = s = Dan.serverboot(\internal, \rme);
	Server.default = s = Dan.serverboot(\internal, \builtin);
	*/
	*serverboot {|prox=\internal, device=\rme, rate=44100|
		var server, options;
		//set up generous defaults; what is this, a raspberry pi?
		options = ServerOptions.new;
		options.numWireBufs_(1024);
		options.maxNodes_(4096);
		options.numControlBusChannels_(4096);
		options.numAudioBusChannels_(1024);
		options.memSize_(131072);
		options.sampleRate = rate;
		options.device = nil;
		//this one works:
		//options.device = nil;
		//these two, they don't work
		//options.inDevice = "Built-in Microphone";
		//options.outDevice = "Built-in Output";
		//this one does work, if you build an aggregate sound device out of your inputs, and give it this name
		//options.device="internal";
		device.switch(
			\motu, {
				options.device = "MOTU UltraLite mk3 Hybrid";
				//make sure we get spdif ins too
				options.numInputBusChannels_(20);
			},
			\rme, {
				options.device = "Fireface UCX";
				//make sure we get spdif ins too
				options.numInputBusChannels_(20);
			},
			\jack, {
				//TODO find this out when JackRouter is running before accepting
				options.device = "JackRouter";
				options.numInputBusChannels_(20);
			},
			\builtin, {
				options.device ="internal";
			}
		);
		options.asOptionsString.postln;
		server = Server.perform(prox);
		server.serverRunning.if({
			server.reboot(server.options_(options));
		}, {
			server.options_(options);
			server.boot;
		});
		//server.doWhenBooted({StartUp.run;});

		//[server, device].postln;
		// Time to send messages to the server. Defaults to 0.2.
		//server.latency = 0.05;
		^server;
	}
	/*
	 * This little guy pans a sawtooth across an arbitrary array of channels for speaker alignment/level
	 * checking
	Dan.panchantest.(bus: Bus.newFrom(s.outputBus,0,3), numChans:4);
	 */
	*panchantest {|bus, numChans, freq=100, rate=1|
		^{Out.ar(bus, PanAz.ar(numChans, in: Saw.ar(freq, mul:0.5), pos: LFSaw.kr(rate)*2))}.play;
	}
}