(
var state = Environment.new(know:true);
~state = state;
state.server = Dan.serverboot(prox:\local, device:\builtin);
)
(
var state = ~state;
state.server.doWhenBooted {~state.make({
	~buf = Buffer.alloc(~server, 441000);
	~loopphasebus = Bus.control(~server, 1);
	~server.sync;
	~buf.readChannel(PS.scsamplepath +/+ "actors-siren.wav");
	~clock=TempoClock.default;
	~host = Synth.new(\ps_bufwr_phased__1x1, [
		\in, ~server.inputBus.subBus(0,1),
		\trig, 1.0,
		\bufnum, ~buf,
		\fadetime,0.0,
		\phasebus, ~loopphasebus,
		\addAction, \head,
	]);
	~parasite = Pbind(
		\instrument, \ps_bufrd_phased_mod__1x2,
		\out, 0,
		\bufnum, ~buf,
		\basedeltime, 0.5,
		\phasebus, ~loopphasebus,
		\rate, 1.0,
		\modulate, 0,
		\modlag, 0.5,
		\pan, 0,
		\amp, 1,
		\gate, 1,
		\attack, 0.01,
		\decay, 0.1,
		\sustainLevel, 1.0,
		\release, 0.5,
		\maxDur, inf,
		\dur, Pn(10, inf),
		\addAction, \addToTail,
		\voxnum, Pseries,
		\attack, 1,
		\decay, 1,
	).trace.play(~clock);
});};
)
~state.server = Dan.serverboot(prox:\local, device:\builtin);
