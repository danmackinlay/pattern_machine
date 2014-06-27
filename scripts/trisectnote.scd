/*
* Messing around trying to find a low-dimensional feature vector that represents harmonicity
Right now, problem is that because there isn't necessarily much energy aroudn 220hz, not clear how to normalise the signal to represent that fact
normalise based on how much power is in that octave?

* remedial trigonometry:
  * * https://en.wikipedia.org/wiki/List_of_trigonometric_identities#Angle_sum_and_difference_identitieshttp://www.sosmath.com/trig/Trig5/trig5/trig5.html

*/
s=~serverboot.(prox:\local, device:\builtin);
(
var analNode;
SynthDef.new(\transect12__1, {|inbus=0,basef=220,outbus,smoothness=8|
	var attackTime, delTimes, sig, inamp, refamps;
	//should individual bands have their own attack rates?
	//should we exploit diff attack and decays?
	attackTime=basef.reciprocal*smoothness;
	delTimes=Array.geom(12,basef.reciprocal,2**(-1.0/12.0));
	sig = In.ar(inbus,1);
	inamp = Amplitude.kr(
		sig.squared,
		attackTime:attackTime,
		releaseTime:attackTime,
	).sqrt.max(0.0001);
	refamps = Amplitude.kr(
		(DelayC.ar(sig, delaytime:delTimes) * sig).squared,
		attackTime:attackTime,
		releaseTime:attackTime,
	).sqrt.max(0.0001)/inamp;
	//TextVU.ar(5, refamps, "Analy");
	Out.kr(outbus, refamps ++ [inamp]);
}).add;

fork {
	~infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	~infilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	~inBus = Bus.audio(s,1);
	~analBus = Bus.control(s,13);
	//~meter=~analBus.makeBusMeter;
	~inBuf=Buffer.read(s,~infilep,action:{|...args| \inbuf.postln;args.postln;});
	s.sync;
	~soundsource = Synth.new(\playbuf__1, [\bufnum,~inBuf, \outbus, ~inBus], s, \addToHead);
	analNode=Synth.new(\transect12__1, [\inbus, ~inBus, \outbus, ~analBus], s, \addToTail);
	~state=(
		analNode:analNode
	);
};
)
~analBus.get;
~analBus.get({|l|{l.plot}.defer;});
~inBuf.plot;
~inBus.