PSEarSwarmController : PSListenSwarmController {
	*new {|server, bus, numChannels=2, fitnessPollInterval=1|
		//simply default to 2 channels
		^super.newCopyArgs(bus, numChannels).init(
			server, fitnessPollInterval);
	}
}