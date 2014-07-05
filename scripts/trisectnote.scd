/*
* Messing around trying to find a low-dimensional feature vector that represents harmonicity

TODO: Filter at control rate to bring the smoothing into line with the offline python analysis

*/
s=~serverboot.(prox:\local, device:\builtin);
(
var analNode;
SynthDef.new(\transect12__1, {|inbus=0,
	basef=220,
	outbus,
	smoothness=4,
	idx=1,
	pollrate=10.0,
	minamp=0.0001|
	var delTimes, delFreqs, sig, inamp, refamps, lowpassF;
	//should individual bands have their own attack rates?
	//should we exploit diff attack and decays?
	delFreqs = Array.geom(12,basef,2**(1.0/12.0));
	delTimes = delFreqs.reciprocal;
	lowpassF = basef/smoothness;
	sig = LeakDC.ar(In.ar(inbus,1));
	inamp = A2K.kr(
		OpLPF.ar(
			sig.squared,
			lowpassF,
			iter: 4
		)
	);
	refamps = A2K.kr(
		OpLPF.ar(
			(DelayC.ar(sig, delaytime:delTimes) * sig),
			lowpassF,
			iter: 4
		)
	)/(inamp.max(minamp));
	refamps = refamps ++ [inamp];
	// TextVU.ar(5, refamps, "Analy");
	Out.kr(outbus, refamps);
	SendReply.kr(
		Impulse.kr(pollrate)*(inamp>minamp),
		'/transect',
		refamps,
		idx);
}).add;

fork {
	s.notify(true);
	~infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	//~infilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	~inBus = Bus.audio(s,1);
	~analBus = Bus.control(s,13);
	//~meter=~analBus.makeBusMeter;
	~inBuf=Buffer.read(s,~infilep,action:{|...args| \inbuf.postln;args.postln;});
	s.sync;
	OSCdef(\transect, { |msg| msg.postln }, '/transect');

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