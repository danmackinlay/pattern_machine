/*
 * Messing around trying to find a low-dimensional feature vector that represents harmonicity
 */
s=~serverboot.(prox:\local, device:\builtin);

s.dumpOSC(1);
OSCdef.trace(true);
s.dumpOSC(0);
OSCdef.trace(false);

(
var analNode, concatNode, soundSource, infilep, confilep, inBuf, conBuf;
var soundAnalBus, transectBus;
var analServer, plotter;
var makeCLI,cli;
var state = (
	pscorrelpath: ~pm +/+ "ps_correl",
	infilep: "/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif",
	//confilep: "/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif",
	confilep: "/Users/dan/src/sc/f_lustre/sounds/draingigm.aif",
	langport: NetAddr.langPort,
	nresults: 6,
	basefreq: 440.0,
);
~state = state;
//cute hack to keep the scripts launching
~correlport = (~correlport ? 36000 + 1).wrap(36000, 36100);
state[\correlport] = ~correlport;

makeCLI = {|settings|
	cli = "python %".format((settings[\pscorrelpath] +/+ "ps_correl.py").shellQuote);
	//This next one is pretty crucial:
	cli = cli ++ " --bus-num=%".format(settings[\transectBus].index);
	//optional:
	settings[\nresults] !? {|a| cli = cli ++ " --n=%".format(a)};
	settings[\rate] !? {|a| cli = cli ++ " --rate=%".format(a)};
	settings[\correlport] !? {|a| cli = cli ++ " --port=%".format(a)};
	settings[\synthport] !? {|a| cli = cli ++ " --sc-synth-port=%".format(a)};
	settings[\langport] !? {|a| cli = cli ++ " --sc-lang-port=%".format(a)};
	settings[\basefreq] !? {|a| cli = cli ++ " --base-freq=%".format(a)};
	settings[\steps] !? {|a| cli = cli ++ " --steps=%".format(a)};
	settings[\minlevel] !? {|a| cli = cli ++ " --min-level=%".format(a)};
	settings[\confilep] !? {|a| cli = cli ++ "  %".format(a)};
	cli;
};
~makeCLI = makeCLI;

SynthDef.new(\transect12__1, {
	|inbus=0,
	basef=440.0,
	cutoff=80.0,
	idx=1,
	pollrate=10.0,
	minamp=0.0001|
	var delTimes, delFreqs, sig, inamp, corrs, lowpassF;
	delFreqs = Array.geom(12,basef,2**(1.0/12.0));
	delTimes = delFreqs.reciprocal;
	sig = LeakDC.ar(In.ar(inbus,1));
	inamp = A2K.kr(
		OpLPF.ar(
			sig.squared,
			cutoff,
			iter: 4
		)
	);
	corrs = A2K.kr(
		OpLPF.ar(
			(DelayC.ar(sig, delaytime:delTimes) * sig),
			cutoff,
			iter: 4
		)
	)/(inamp.max(minamp));
	//include amplitude info in query
	corrs = [inamp] ++ corrs;
	SendReply.kr(
		Impulse.kr(pollrate)*(inamp>minamp),
		'/transect',
		corrs,
		idx);
}).add;
SynthDef.new(\concat__1_1, {|outbus,
	bufnum,
	time=0,
	playrate=1,
	grainrate=80.0,
	overlap=2,
	jitter=0,
	pregain=1,
	amp=1,
	badness=0,
	maxBadness=2.0|
	var sig, trig, dur, jitdur;
	trig = Impulse.ar(grainrate);
	dur = grainrate.reciprocal*overlap;
	jitdur = dur*jitter/2;
	// Should probably be TGrains:
	sig = TGrains.ar (
		numChannels:2,
		trigger: trig,
		bufnum: bufnum,
		rate: BufRateScale.kr(bufnum)*playrate,
		centerPos: TRand.ar(jitdur.neg, jitdur, trig)+ time,
		dur: dur,
		pan: -1,
		amp: pregain*(badness<maxBadness),
		interp: 1)[0];
	/*
	sig = GrainBuf.ar(
		numChannels:1,
		sndbuf: bufnum,
		rate: BufRateScale.kr(bufnum)*playrate,
		trigger: trig,
		pos: TRand.ar(jitdur.neg, jitdur, trig)+ time,
		dur: dur,
		mul: pregain,
	);
	*/
	Out.ar(outbus, sig*amp);
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
	//soundAnalBus = Bus.audio(s,1);
	inBuf=Buffer.read(s,state[\infilep]);
	conBuf=Buffer.read(s,state[\confilep]);
	transectBus = Bus.control(s, numChannels: state[\nresults]*3);
	s.sync;
	state.putAll((
		transectBus:transectBus,
		inBuf: inBuf,
		conBuf: conBuf,
	));
	OSCdef(\transect,
		{ |msg|
			var vals=msg[3..];
			// vals.postln;
			state[\anal]=vals;
		}, '/transect'
	);
	soundSource = Synth.new(\playbuf__1, [\bufnum, inBuf, \outbus, soundAnalBus], s, \addToHead);
	analNode=Synth.new(\transect12__1, [
		\inbus, soundAnalBus, \outbus,
		transectBus,
		\pollrate, 160.0
	], s, \addToTail);
	concatNode=Synth.new(\concat__1_1, [
		\outbus, 1,
		\bufnum, conBuf,
		\time, transectBus.subBus(0,1).asMap,
		\jitter, 0.0,
		\overlap, 4,
		\grainrate, 20,
		\amp, 0.5,
		\pregain, transectBus.subBus(6,1).asMap,
		\badness, transectBus.subBus(12,1).asMap,
		\maxBadness, 2
	], s, \addToTail);
	state.putAll((
		analNode: analNode,
		concatNode: concatNode,
		soundSource: soundSource,
		inBuf: inBuf,
		conBuf: conBuf,
		soundAnalBus: soundAnalBus,
	));
	cli = makeCLI.value(state);
	state[\cli] = cli;
	~cli=cli;
	s.sync;
	~cli.runInTerminal;
	// ~dataServerPid = -1000;
	// ~dataServerPid.pidRunning.not.if({
	// ~dataServerPid= (~cli).unixCmd(
	// 		action: {|result, pid| [result, pid].postln},
	// 		postOutput: true
	// 	);
	// });
	~state = state;
};
)
~state;
~state.cli;
~makeCLI.value(~state);
~state.transectBus.index
~state.transectBus.get;
~state.transectBus.subBus(12,1).get;
~state.conBuf;