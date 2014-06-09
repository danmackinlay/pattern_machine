/*
See also bassExplore.scd

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

s=~serverboot.(prox:\local, device:\internal);
s=~serverboot.(prox:\local, device:\rme);
~state = 'foo';
(
var inbus, outbus, ingroup, voxgroup, fxgroup, postgroup, testsample, testbuf, envBuf, state;
state = ();
testsample = ~zamples +/+ "SupercolliderAuxiliary" +/+ "NS wind chimes 002-denoise-edit.aiff";
fork {
	SynthDef.new(\decijules,
	{|in,
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
		sig=AllpassL.ar(sig, maxdelaytime: 3, delaytime:deltime, decaytime: deldecay);
		sig=Pan2.ar(sig, traj, level: outenv);
		Out.ar(out, sig);
	}).add;
	ingroup = Group.new(s, \addToHead);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	inbus = Bus.audio(s,1);
	outbus = Bus.new(\audio, 0, 2, s);
	testbuf = Buffer.read(s, testsample);
	s.sync;
	~testbuf = testbuf;
	~testsound = (
		instrument: \playbuf__1,
		out: inbus,
		bufnum: testbuf,
		group: ingroup,
		sendGate: false,//won't loop if not told
	).play;
	voxgroup = Group.new(s, \addToTail);
	s.sync;
	fxgroup = Group.new(s, \addToTail);
	s.sync;
	postgroup = Group.new(s, \addToTail);
	s.sync;
	~revLeft = (
		instrument: \mutatingreverb,
		group: fxgroup,
		out: Bus.newFrom(outbus,0,1)
	).play;
	~revRight = (
		instrument: \mutatingreverb,
		group: fxgroup,
		out: Bus.newFrom(outbus,1,1)
	).play;
	~limiter = (
		instrument: \limi__2,
		group: postgroup,
		out:outbus,
	).play;
	p = Pbind(
		\instrument, \decijules,
		\in, inbus,
		\out, outbus,
		\group, voxgroup,
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
	{s.makeGui;}.defer;
	state.putAll((
		outbus: outbus,
		inbus: inbus,
		voxgroup: voxgroup,
	));
	~state = state;
};
)
~state
p.play;
(pitch: 5, group: ~state.voxgroup, out:~state.outbus).play;