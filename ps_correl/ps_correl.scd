/*
 * Messing around trying to find a low-dimensional feature vector that represents harmonicity
 * TODO: work out why last col is always 0.
 */
s=~serverboot.(prox:\local, device:\builtin);
~pscorrelpath = ~pm +/+ "ps_correl";
// ~dataServerPid = -1000;
// ~dataServerPid.pidRunning.not.if({
// ~dataServerPid= "python %".format(
//    (~pscorrelpath +/+ "ps_correl.py").shellQuote
// ).unixCmd(
// 		action: {|result, pid| [result, pid].postln},
// 		postOutput: true
// 	);
// });
"python %".format(
	(~pscorrelpath +/+ "ps_correl.py").shellQuote
).runInTerminal;
s.dumpOSC(1);
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
	corrs = corrs ++ [inamp];
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
	soundAnalBus = Bus.audio(s,1);
	//~meter=transectBus.makeBusMeter;
	inBuf=Buffer.read(s,infilep);
	conBuf=Buffer.read(s,confilep);
	transectBus = Bus.control(s, numChannels: 6);
	analServer = NetAddr("127.0.0.1", 36000);
	s.sync;
	analServer.sendMsg("/set_bus", transectBus.index);
	analServer.sendMsg("/set_n", transectBus.numChannels);
	OSCdef(\transect,
		{ |msg|
			var vals=msg[3..];
			// vals.postln;
			state[\anal]=vals;
		}, '/transect'
	);
	soundSource = Synth.new(\playbuf__1, [\bufnum, inBuf, \outbus, soundAnalBus], s, \addToHead);
	analNode=Synth.new(\transect12__1, [\inbus, soundAnalBus, \outbus, transectBus], s, \addToTail);
	concatNode=Synth.new(\concat__1_1, [\outbus, 0,
		\bufnum, conBuf,
		\time, transectBus.subBus(0,1).asMap,
	], s, \addToTail);
	state.putAll((
		analNode: analNode,
		transectBus: transectBus,
		analServer: analServer,
		concatNode: concatNode,
		soundSource: soundSource,
		infilep: infilep,
		confilep: confilep,
		inBuf: inBuf,
		conBuf: conBuf,
		soundAnalBus: soundAnalBus,
		transectBus: transectBus,
	));
};
)
~state;