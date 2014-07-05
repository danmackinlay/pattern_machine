/*
* Messing around trying to find a low-dimensional feature vector that represents harmonicity

TODO: Filter at control rate to bring the smoothing into line with the offline python analysis

*/
s=~serverboot.(prox:\local, device:\builtin);
(
var analNode;
SynthDef.new(\transect12__1, {|inbus=0,basef=220,outbus,smoothness=8, idx=1, pollrate=80.0|
	var attackTime, delTimes, sig, inamp, refamps, coefs;
	//should individual bands have their own attack rates?
	//should we exploit diff attack and decays?
	attackTime=basef.reciprocal*smoothness;
	delTimes=Array.geom(12,basef.reciprocal,2**(-1.0/12.0));
	sig = In.ar(inbus,1);
	coefs = (0.0001.log/(delTimes*SampleRate.ir)).exp;
	inamp = A2K.kr(
		OnePole.ar(sig.squared, coef:coef)
	);
	refamps = A2K.kr(
		OnePole.ar((DelayC.ar(sig, delaytime:delTimes) * sig), coef:coef)
	)/(inamp.max(0.0001));
	refamps = refamps ++ [inamp];
	//TextVU.ar(5, refamps, "Analy");
	Out.kr(outbus, refamps);
	SendReply.kr(
		Impulse.kr(pollrate)*(inamp>0.0001),
		'/transect',
		refamps,
		idx);
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