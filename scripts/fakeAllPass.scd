/*
See also marsenator.scd

I am trying to a reversible reverb-echo like effect, where the diffusion can be undone.
*/

s=~serverboot.(prox:\local, device:\internal);
s=~serverboot.(prox:\local, device:\rme);
~state = 'foo';
(
var inbus, outbus, ingroup, voxgroup, fxgroup, postgroup, testsample, testbuf, envBuf, state, freqMap, minFreq=55, nOctaves=8, nBpBandsPerOctave=3,nBpBandsTotal,allBpFreqs,bwr;
nBpBandsTotal=nBpBandsPerOctave*nOctaves+1;
bwr = nBpBandsTotal.reciprocal;
freqMap = {|v| 2**v.linlin(0.0,1.0,0.0,nOctaves)*minFreq };
allBpFreqs = (Array.series(nBpBandsTotal)/nBpBandsTotal).collect(freqMap);
	//Should I do this as Linkwitz Riley crossovers? BPF for now
SynthDef(\fakeDiffusion,{
	|out,dry=0, decoherence=0, delay=0.2, inxfade=(-1.0), outxfade=0.0, lag=0.1|
	var bands, dels, deltimes, fbins, sig;
	deltimes = Lag.ar(
		(DC.ar(delay) *
			(1+
				(decoherence *
					Array.series(nBpBandsTotal) /nBpBandsTotal)
			)
		) - ControlRate.ir.reciprocal,
		lag);
	fbins = DelayC.ar(LocalIn.ar(nBpBandsTotal), 1, deltimes);
	sig = In.ar(out);
	LocalOut.ar(
		XFade2.ar(
			BPF.ar(sig,allBpFreqs,bwr),
			fbins,
			inxfade
		)
	);
	ReplaceOut.ar(out, XFade2.ar(
		sig,
		Mix(fbins),
		outxfade
	));
}).dumpUGens.add;

state = ();
fork {
	ingroup = Group.new(s, \addToHead);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	inbus = Bus.audio(s,1);
	outbus = Bus.new(\audio, 0, 2, s);
	testbuf = Buffer.read(s, testsample);
	s.sync;
	~testbuf = testbuf;
	~testsound = (
		instrument: \playbuf__1,
		out: inbus,
		bufnum: testbuf,
		group: ingroup,
		sendGate: false,//won't loop if not told
	).play;
	voxgroup = Group.new(s, \addToTail);
	s.sync;
	fxgroup = Group.new(s, \addToTail);
	s.sync;
	postgroup = Group.new(s, \addToTail);
	s.sync;
	~fakeDiffusionL = (
		instrument: \fakeDiffusion,
		group: fxgroup,
		out: Bus.newFrom(outbus,0,1)
	).play;
	~fakeDiffusionR = (
		instrument: \fakeDiffusion,
		group: fxgroup,
		out: Bus.newFrom(outbus,1,1)
	).play;
	~limiter = (
		instrument: \limi__2,
		group: postgroup,
		out:outbus,
	).play;
	state.putAll((
		outbus: outbus,
		inbus: inbus,
		voxgroup: voxgroup,
	));
	~state = state;
};
)
(pitch: 5, group: ~state.voxgroup, out:~state.outbus).play;