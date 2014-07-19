/*
 * Messing around trying to find a low-dimensional feature vector that represents harmonicity
 */
s=~serverboot.(prox:\local, device:\builtin);
~pscorrelpath = ~pm +/+ "ps_correl";
~cli = "python %".format((~pscorrelpath +/+ "ps_correl.py").shellQuote);
// ~dataServerPid = -1000;
// ~dataServerPid.pidRunning.not.if({
// ~dataServerPid= (~cli).unixCmd(
// 		action: {|result, pid| [result, pid].postln},
// 		postOutput: true
// 	);
// });
(~cli).runInTerminal;

s.dumpOSC(1);
OSCdef.trace(true);

s.dumpOSC(0);
OSCdef.trace(false);

(
var analNode, concatNode, soundSource, infilep, confilep, inBuf, conBuf;
var soundAnalBus, transectBus;
var analServer, plotter;
var state=();
~state = state;
SynthDef.new(\transect12__1, {|inbus=0,
	basef=440.0,
	smoothness=4,
	idx=1,
	pollrate=10.0,
	minamp=0.0001|
	var delTimes, delFreqs, sig, inamp, corrs, lowpassF;
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
	corrs = A2K.kr(
		OpLPF.ar(
			(DelayC.ar(sig, delaytime:delTimes) * sig),
			lowpassF,
			iter: 4
		)
	)/(inamp.max(minamp));
	//include amplitude info in query (currently ignored)
	corrs = [inamp] ++ corrs;
	// TextVU.ar(5, corrs, "Analy");
	SendReply.kr(
		Impulse.kr(pollrate)*(inamp>minamp),
		'/transect',
		corrs,
		idx);
}).add;
SynthDef.new(\concat__1_1, {|outbus=0,
	bufnum,
	time, rate=1|
	var sig, phase;
	sig = GrainBuf.ar(
		numChannels:1,
		sndbuf: bufnum,
		rate: 1,
		trigger: 1,
		pos: time,
		dur: 0.1);
	Out.ar(outbus, sig);
}).add;

state.putAll((
	anal: Array.fill(13,0),
));
plotter = Plotter(\anal);
plotter.minval_(-1);
plotter.maxval_(1);
state[\plotter] = plotter;
state[\plotterrout] = AppClock.play(
	Routine({
		{state[\plotter].notNil}.while({
			plotter.value = state[\anal];
			plotter.minval_(-1);
			plotter.maxval_(1);
			0.1.yield;
		})
	})
);
fork {
	s.notify(true);
	infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	confilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	//soundAnalBus = Bus.audio(s,1);
	//~meter=transectBus.makeBusMeter;
	inBuf=Buffer.read(s,infilep);
	conBuf=Buffer.read(s,confilep);
	//transectBus = Bus.control(s, numChannels: 6);
	transectBus = Bus.new(\audio, index: 83, numChannels: 6, server: s);
	s.sync;
	OSCdef(\transect,
		{ |msg|
			var vals=msg[3..];
			// vals.postln;
			state[\anal]=vals;
		}, '/transect'
	);
	soundSource = Synth.new(\playbuf__1, [\bufnum, inBuf, \outbus, soundAnalBus], s, \addToHead);
	analNode=Synth.new(\transect12__1, [\inbus, soundAnalBus, \outbus, transectBus, \pollrate, 1.0], s, \addToTail);
	concatNode=Synth.new(\concat__1_1, [\outbus, 0,
		\bufnum, conBuf,
		\time, transectBus.subBus(0,1).asMap,
	], s, \addToTail);
	state.putAll((
		analNode: analNode,
		transectBus: transectBus,
		concatNode: concatNode,
		soundSource: soundSource,
		infilep: infilep,
		confilep: confilep,
		inBuf: inBuf,
		conBuf: conBuf,
		soundAnalBus: soundAnalBus,
	));
};
)
~state;
~state.transectBus.get;
