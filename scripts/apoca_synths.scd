SynthDef.new(\echette_live__1_2,
	{|inbus=0, outbus=0, deltime=0.1, ringtime=1, pan=0|
		var env, sig;
		sig = In.ar(inbus, 1) * EnvGen.kr(Env.sine(dur:deltime));
		env = EnvGen.kr(
			Env.linen(
				attackTime:0,
				sustainTime:deltime,
				releaseTime:ringtime
			), gate:1, doneAction:2
		);
		sig = AllpassN.ar(sig,
			delaytime: deltime,
			decaytime: ringtime,
			maxdelaytime: 0.5,
			mul: env);
		sig = Pan2.ar(sig, pos:pan);
		Out.ar(outbus, sig);
	}
).add;
//ChannelMixer test thingy
//a = echettechannel1.play("pinkfilt", [\freq, 2000, \rq, 0.02, \out, echettechannel1.inbus.index]);
SynthDef.new("pinkfilt", {
	arg	outbus,	// outbus is the standard name used by MixerChannel
		freq, rq;
	Out.ar(outbus, RLPF.ar(PinkNoise.ar, freq, rq));
}).add;

// ChannelMixer fx test thingy
// f= echettechannel1.playfx("fx/chorus1x1");	// so it goes to effectgroup
SynthDef.new("fx/chorus1x1", {
	arg outbus, delay = 0.01, freq = 0.2, depth = 0.05, wet = 0.5;
	var in, out;
	in = In.ar(outbus, 1);
	out = DelayN.ar(in, 1, SinOsc.ar(freq, 0, depth, delay));
	ReplaceOut.ar(outbus, in*(1-wet).sqrt + out*wet.sqrt);	// equal power
}).add;

