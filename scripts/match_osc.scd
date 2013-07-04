(
var left, right, master, slave, periodestimatebus, secretfrequency;
s = Server.default;
s.boot;
left = Bus.new(\audio, 0,1);
right = Bus.new(\audio, 1,1);
periodestimatebus = Bus.control(s,1);
//choose our secret frequency here for later comparison:
secretfrequency = rrand(2.0,5.0);

//generate impulse with secret frequency at some arbitrary phase
master = {Impulse.ar(secretfrequency, Rand(0, 1));}.play(s, left);

slave = {
	var masterin, clockcount, clockoffset, syncedclock, periodestimate, tracking;
	masterin = In.ar(left);
	//This 1 Hz LFSaw is the "clock" against which we measure stuff
	clockcount = LFSaw.ar(1, 0, 0.5, 0.5);
	clockoffset = Latch.ar(clockcount, Delay1.ar(masterin));
	syncedclock = (clockcount - clockoffset).frac;
	//syncedclock is a version of the clock hard-reset (one sample after) every impulse trigger
	periodestimate = Latch.ar(syncedclock, masterin);
	//sanity-check our f impulse
	Out.kr(periodestimatebus, periodestimate);
	//there is no phase estimate per se - what would we measure it against? -
	//but we can resynthesise a new impulse up to a 1 sample delay from the matched clock.
	tracking = (Slope.ar(syncedclock)>0);
}.play(master, right, 0, addAction: \addAfter);

//Let's see how we performed
{
	periodestimatebus.get({|periodestimate|
		["actual/estimated frequency", secretfrequency, periodestimate.reciprocal].postln;
	});
}.defer(1);
)
