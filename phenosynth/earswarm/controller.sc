PSEarSwarmController : PSListenSynthSwarmController {
	classvar <listenSynth = \ps_conv_eight_hundred;
	*new {|server, bus, numChannels=2, q, fitnessPollInterval=1|
		//simply default to 2 channels
		^super.newCopyArgs(bus, numChannels, q).init(
			server, fitnessPollInterval);
	}
}