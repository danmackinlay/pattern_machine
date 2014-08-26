/*
See also marsenator.scd

I am trying to create a reversible reverb-echo like effect, where the
diffusion can be undone.
*/

s=~serverboot.(prox:\local, device:\builtin);
s=~serverboot.(prox:\local, device:\rme);
~state = 'foo';
(
var inbus, outbus, ingroup, voxgroup, fxgroup, postgroup, testsample, testbuf, envBuf, state, freqMap, minFreq=55, nOctaves=8, nBpBandsPerOctave=1, nBpBandsTotal, allBpFreqs ,bwr;
nBpBandsTotal=nBpBandsPerOctave*nOctaves+1;

bwr = nBpBandsTotal.reciprocal;
freqMap = {|v| 2**v.linlin(0.0,1.0,0.0,nOctaves)*minFreq };
allBpFreqs = (Array.series(nBpBandsTotal)/nBpBandsTotal).collect(freqMap);
	//Should I do this as Linkwitz Riley crossovers? BPF for now
SynthDef(\fakeDiffusion,{
	|out, macrodecoherence=0, macrodelay=0.2, microdecoherence=(-0.25), microdelay=0.033, microdecay=0.2, inxfade=0.0, outxfade=0.0, lag=0.5|
	var bands, dels, macrodeltimes, microdeltimes, fbins, sig, blockTime;
	blockTime = ControlRate.ir.reciprocal;
	macrodeltimes = nBpBandsTotal.collect({|i|
		Lag.ar(
			in: DC.ar(
				((
					((macrodecoherence * i/nBpBandsTotal) + 1) * macrodelay
				) - blockTime)
			),
			lagTime: lag
		);
	});
	microdeltimes = nBpBandsTotal.collect({|i|
		Lag.ar(
			in: DC.ar((
					((microdecoherence * i/nBpBandsTotal) + 1) * microdelay
			)),
			lagTime: lag
		).poll(1,\micro);
	});
	fbins = DelayC.ar(
		in: LocalIn.ar(nBpBandsTotal),
		maxdelaytime: 2.0,
		delaytime: macrodeltimes
	);
	sig = In.ar(outbus);
	LocalOut.ar(
		XFade2.ar(
			BPF.ar(sig,allBpFreqs,bwr),
			fbins,
			VarLag.kr(inxfade)
		)
	);
	//Amplitude.kr(fbins).ampdb.poll(1,\amp);
	ReplaceOut.ar(outbus, XFade2.ar(
		sig,
		Mix(
			AllpassC.ar(
				in:fbins,
				maxdelaytime: 1.0,
				delaytime: microdeltimes,
				decaytime: microdecay)
		),
		VarLag.kr(outxfade)
	));
}).add;

state = ();
testsample = PS.samplepath +/+ "SupercolliderAuxiliary" +/+ "NS-wind-chimes-002-denoise-edit.wav";
{s.makeGui;}.defer;
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
	/*~fakeDiffusionL = (
		instrument: \fakeDiffusion,
		group: fxgroup,
		out: Bus.newFrom(outbus,0,1)
	).play;
	~fakeDiffusionR = (
		instrument: \fakeDiffusion,
		group: fxgroup,
		out: Bus.newFrom(outbus,1,1)
	).play;*/
	~fakeDiffusionL = Synth(
		\fakeDiffusion, [
			\outbus, Bus.newFrom(outbus,0,1),
			\macrodecoherence, 0.5,
			\inxfade, 0.7,
		],
		target: fxgroup,
	);
	~fakeDiffusionR = Synth(
		\fakeDiffusion, [
			\outbus, Bus.newFrom(outbus,1,1),
			\macrodecoherence, 0.5,
		],
		target: fxgroup,
	);
	~limiter = (
		instrument: \limi__2,
		group: postgroup,
		out:outbus,
	).play;
	state.putAll((
		outbus: outbus,
		inbus: inbus,
		ingroup: ingroup,
		voxgroup: voxgroup,
		fxgroup: fxgroup,
		postgroup: postgroup,
	));
	~pat = Pbind(
		\note, Pseq([0,3,7,12],inf),
		\group, ~state.voxgroup,
		\outbus, ~state.outbus,
		\dur, 1).play;
	~state = state;
};
)
(pitch: 5, group: ~state.voxgroup, out:~state.outbus).play;
~fakeDiffusionL.set(\lag, 1);
~fakeDiffusionL.set(\lag, 0.1);
~fakeDiffusionL.set(\lag, 0);
~fakeDiffusionL.set(\macrodelay, 0.5);
~fakeDiffusionL.set(\macrodelay, 0.2);
~fakeDiffusionL.set(\macrodecoherence, -1.0);
~fakeDiffusionL.set(\macrodecoherence, 0.0);
~fakeDiffusionL.set(\macrodecoherence, 1.0);
~fakeDiffusionL.set(\microdelay, 0.1);
~fakeDiffusionL.set(\microdelay, 0.01);
~fakeDiffusionL.set(\microdecoherence, -1.0);
~fakeDiffusionL.set(\microdecoherence, 0.0);
~fakeDiffusionL.set(\microdecoherence, 1.0);
~fakeDiffusionL.set(\inxfade, 1.0);
~fakeDiffusionL.set(\inxfade, 0.7);
~fakeDiffusionL.set(\inxfade, 0.0);
~fakeDiffusionL.set(\inxfade, -0.7);
~fakeDiffusionL.set(\inxfade, -1.0);
~fakeDiffusionL.set(\outxfade, 1.0);
~fakeDiffusionL.set(\outxfade, 0.0);
~fakeDiffusionL.set(\outxfade, -1.0);
