/*
See also bassExplore

I am trying to create flocks of granular effects, with a consistent aggregate sound.

That is not insurmountable; The question here is how i can *evolve* it interestingly? I see something where you could ramp up the effect until it became really nuts; looping backwards *and* forwards;

2 types of effects woudl be interesting:
1 enveloped delayed live input,
2 approximated sample-library stuff, batchNRT-style.

Some stuttering would be nice too.
There should be an adjustable delay instrument that gives us this.

Simple idea, might work: every grain controlled by correlation at specified level with "trajectory" oscillator

TODO: compressor.
TODO: delayscape
TODO: bassier samples
*/

(
var state;
state = ();
fork {
	~state = state.make({
	~testsamplepath = PS.scsamplepath +/+ "NS-wind-chimes-002-denoise-edit.wav";
	SynthDef.new(\decijules, {|in,
		out,
		trajrate=1,
		len=0.3,
		phase=3,
		deltime=0.2,
		gate=1,
		attack=0.1,
		release=1,
		deldecay=1|
	var traj, sig, pan, inenv, outenv;
		traj = LFTri.kr(trajrate, iphase: phase);
		inenv = EnvGen.kr(Env.asr(attackTime: attack, releaseTime:release, curve:\sine), gate:gate);
		outenv = EnvGen.kr(Env.linen(attack, len, release,curve:\sine), gate:gate, doneAction:2);
		sig=In.ar(in)*inenv;
		//sig=AllpassL.ar(sig, maxdelaytime: 3, delaytime:deltime, decaytime: deldecay);
		sig=Pan2.ar(sig, traj, level: outenv);
		Out.ar(out, sig);
	}).add;
	~ingroup = Group.new(s, \addToHead);
	~inbus = Bus.newFrom(s.inputBus,0,1);
	//~inbus = Bus.audio(s,1);
	~outbus = Bus.new(\audio, 0, 2, s);
	~testbuf = Buffer.read(s, ~testsamplepath);
	s.sync;
	~testsound = (
		instrument: \playbuf__1x2,
		out: ~inbus,
		bufnum: ~testbuf,
		group: ~ingroup,
		sendGate: false,//won't loop if not told
	).play;
	~voxgroup = Group.new(s, \addToHead);
	~fxgroup = Group.new(s, \addToTail);
	s.sync;
	~postgroup = Group.new(s, \addToTail);
	s.sync;
	~revLeft = (
		instrument: \ps_mutatingreverb_4__1x1,
		group: ~fxgroup,
		out: Bus.newFrom(~outbus,0,1)
	).play;
	~revRight = (
		instrument: \ps_mutatingreverb_4__1x1,
		group: ~fxgroup,
		out: Bus.newFrom(~outbus,1,1)
	).play;
	~limiter = (
		instrument: \limi__2x2,
		group: ~postgroup,
		out: ~outbus,
	).play;
	~p = Pbind(
		\instrument, \decijules,
		\in, ~inbus,
		\out, ~outbus,
		\group, ~voxgroup,
		\sustain, Pwhite(1.0,3.0,inf),//input gate
		\len, Pwhite(2.0,10.0), //output gate
		\attack, Pwhite(0.01,0.1,inf),
		\release, Pwhite(2.0,10.0),
		\phase, Pwhite(0.0,4.0,inf),
		\trajrate, Pwhite(0.05,1.0,inf),
		\delta, Pn(0, 8),
		\deltime, Pwhite(0.01,0.98,inf).log.neg*0.3,
		\deldecay, (Pkey(\release) + Pkey(\len))*2,

	).collect(_.postln);
	});
};
)
~state.p.play;
~state.testbuf;
(pitch: 5, group: ~state.voxgroup, out:~state.out).play;
{s.makeGui;}.defer;
