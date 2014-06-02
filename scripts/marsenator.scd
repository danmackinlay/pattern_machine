/*
See also bassExplore.scd

I am trying to create flocks of granular effects, with a consistent aggregate sound.

That is not insurmountable; The question here is how i can *evolve* it interestingly? I see something where you could ramp up the effect until it became really nuts; looping backwards *and* forwards;

2 types of effects woudl be interesting:
1 enveloped delayed live input,
2 approximated sample-library stuff, batchNRT-style.

Some stuttering would be nice too.

Simple idea, might work: evey grain controlled by correlation at specified level with "trajectory" oscillator

TODO: compressor:
*/

s=~serverboot.(prox:\local, device:\internal);
s=~serverboot.(prox:\local, device:\rme);
s.makeGui;
(
SynthDef.new(\decijules,
	{|in,
		out,
		trajrate=1,
		inlength=0.3,
		phase=3,
		deltime=0.2,
		trig=1,
		attack=0.1,
		release=1,
		deldecay=1|
	var traj, sig, pan, inenv, outenv;
		traj = LFTri.kr(trajrate, iphase: phase);
		inenv = EnvGen.kr(Env.sine(inlength),gate:trig);
		outenv = EnvGen.kr(Env.perc(attack, release), gate:trig, doneAction:2);
		sig=In.ar(in)*inenv;
		sig=AllpassL.ar(sig, maxdelaytime: 3, delaytime:deltime, decaytime: deldecay);
		sig=Pan2.ar(sig, traj, level: outenv);
		Out.ar(out, sig);
}).add;
)
(
var inbus, outbus, ingroup, delaygroup, postgroup, testsample, testbuf;
testsample = ~zamples +/+ "SupercolliderAuxiliary" +/+ "NS wind chimes 002-denoise-edit.aiff";
fork {
	ingroup = Group.new(s, \addToHead);
	inbus = Bus.newFrom(s.inputBus,0,1);
	outbus = Bus.new(\audio, 0, 2, s);
	testbuf = Buffer.read(s, testsample);
	s.sync;
	~testbuf = testbuf;
	delaygroup = Group.new(s, \addToTail);
	s.sync;
	postgroup = Group.new(s, \addToTail);
	s.sync;
	p = Pbind(
		\instrument, \decijules,
		//\in, inbus,
		\in, 0,
		\out, outbus,
		\group, delaygroup,
		\delta, Pn(0, 8),
		\phase, Pwhite(0.0,4.0,inf),
		\trajrate, Pwhite(1.0,2.0,inf),
		\deltime, Pwhite(0.001,1.0,inf).log.neg*0.3,
		\attack, Pwhite(0.001,1.0,inf).log.neg*0.1,
		\release, Pwhite(0.001,1.0,inf).log.neg*2,
		\deldecay, Pwhite(0.001,1.0,inf).log.neg*1,
		\inlength, 0.5,
	).collect(_.postln);
}
)
p.play;
~testbuf.play(loop:true);