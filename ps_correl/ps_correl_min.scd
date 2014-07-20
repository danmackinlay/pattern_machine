(
var state = ();

SynthDef.new(\concat__1_1, {|outbus,
	bufnum,
	time=0,
	playrate=1,
	grainrate=80.0,
	overlap=2,
	jitter=0|
	var sig, trig, dur, jitdur;
	trig = Impulse.ar(grainrate);
	dur = grainrate.reciprocal*overlap;
	jitdur = dur*jitter/2;
	// Should probably be TGrains:
	/*
	sig = TGrains.ar (
		numChannels:2,
		trigger: trig,
		bufnum: bufnum,
		rate: BufRateScale.kr(bufnum)*playrate,
		centerPos: TRand.ar(jitdur.neg, jitdur, trig)+ time,
		dur: dur,
		pan: -1, amp: 2, interp: 4)[0];
	*/
	sig = GrainBuf.ar(
		numChannels:1,
		sndbuf: bufnum,
		rate: BufRateScale.kr(bufnum)*playrate,
		trigger: trig,
		pos: TRand.ar(jitdur.neg, jitdur, trig)+ time,
		dur: dur,
		mul: 2,
	);
	Out.ar(outbus, sig);
}).add;

fork {
	var confilep, conBuf, concatNode;
	//confilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	confilep="/Users/dan/src/sc/f_lustre/sounds/draingigm.aif";
	conBuf=Buffer.read(s,confilep);
	s.sync;
	concatNode=Synth.new(\concat__1_1, [
		\outbus, 1,
		\bufnum, conBuf,
		\time, 22.0,
		\jitter, 0.5,
		\overlap, 4,
		\grainrate, 5
	], s, \addToTail);
	state.putAll((
		concatNode: concatNode,
		confilep: confilep,
		conBuf: conBuf,
	));
};
~state = state;
)
~state.conBuf.plot;