/*
* Messing around trying to find a low-dimensional feature vector that represents harmonicity

TODO: Filter at control rate to bring the smoothing into line with the offline python analysis
TODO: plotter cleanup
TODO: launch or wrap python server
*/
s=~serverboot.(prox:\local, device:\builtin);
~dataServerPid = -1000;
~dataServerPid.pidRunning.not.if({
	~dataServerPid= "python %".format(
		(~pmextern +/+ "ps_correl.py").shellQuote
	).unixCmd(
		action: {|result, pid| [result, pid].postln},
		postOutput: true
	);
});
s.dumpOSC(1);
(
var analNode, plotter, analBus, analServer, state=();
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
SynthDef.new(\concat__1_1, {|outbus=0,
	bufnum,
	time, rate|
	var sig, phase;
	sig = SinOsc.ar(440);

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
	~infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	//~infilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	~inBus = Bus.audio(s,1);
	//~meter=~analBus.makeBusMeter;
	~inBuf=Buffer.read(s,~infilep);
	analBus = Bus.control(s, numChannels: 6);
	analServer = NetAddr("127.0.0.1", 36000);
	s.sync;
	analServer.sendMsg("/set_bus", analBus.index);
	analServer.sendMsg("/set_n", analBus.numChannels);
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
		analBus: analBus,
		analServer: analServer,
	));
};
)
