/*
* Messing around trying to find a low-dimensional feature vector that represents harmonicity

TODO: Filter at control rate to bring the smoothing into line with the offline python analysis
TODO: get plotter live updating; that would be nice.

*/
s=~serverboot.(prox:\local, device:\builtin);

(
var analNode, plotter, state=();
~state = state;
SynthDef.new(\transect12__1, {|inbus=0,
	basef=440.0,
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
	SendReply.kr(
		Impulse.kr(pollrate)*(inamp>minamp),
		'/transect',
		refamps,
		idx);
}).add;
state.putAll((
	anal: Array.fill(13,0),
));
state[\plotter] = AppClock.play(Routine({10.do({state[\anal].plot; 1.yield;})}));
fork {
	s.notify(true);
	~infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	//~infilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	~inBus = Bus.audio(s,1);
	//~meter=~analBus.makeBusMeter;
	~inBuf=Buffer.read(s,~infilep,action:{|...args| \inbuf.postln;args.postln;});
	s.sync;
	OSCdef(\transect,
		{ |msg|
			var vals=msg[3..];
			// vals.postln;
			state[\anal]=vals;
		}, '/transect'
	);

	~soundsource = Synth.new(\playbuf__1, [\bufnum,~inBuf, \outbus, ~inBus], s, \addToHead);
	analNode=Synth.new(\transect12__1, [\inbus, ~inBus, \outbus, ~analBus], s, \addToTail);
	state.putAll((
		analNode: analNode,
	));
};
)
