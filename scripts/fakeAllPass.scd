/*
See also marsenator.scd

I am trying to create a reversible reverb-echo like effect, where the
diffusion can be undone.
TODO: ditch feedback entirely?
TODO: stereo - doesn't work right now because of multiple LocalIn definitions
*/

s=~serverboot.(prox:\local, device:\internal);
s=~serverboot.(prox:\local, device:\rme);
~state = 'foo';
(
var inbus, outbus, ingroup, voxgroup, fxgroup, postgroup, testsample, testbuf, envBuf, state, freqMap, minFreq=55, nOctaves=8, nBpBandsPerOctave=1, nBpBandsTotal, allBpFreqs ,bwr, synthfn;
nBpBandsTotal=nBpBandsPerOctave*nOctaves+1;

bwr = nBpBandsTotal.reciprocal;
freqMap = {|v| 2**v.linlin(0.0,1.0,0.0,nOctaves)*minFreq };
allBpFreqs = (Array.series(nBpBandsTotal)/nBpBandsTotal).collect(freqMap);
	//Should I do this as Linkwitz Riley crossovers? BPF for now
synthfn = {|sig, macrodecoherence=0, macrodelay=0.2, microdecoherence=(-0.25), microdelay=0.033, microdecay=0.2, outxfade=0.0, lag=0.5|
	var bands, dels, macrodeltimes, microdeltimes, fbins, blockTime;
	macrodeltimes = nBpBandsTotal.collect({|i|
		Lag.ar(
			in: K2A.ar(
				((
					((macrodecoherence * i/nBpBandsTotal) + 1) * macrodelay
				))
			),
			lagTime: lag
		);
	});
	microdeltimes = nBpBandsTotal.collect({|i|
		Lag.ar(
			in: K2A.ar((
					((microdecoherence * i/nBpBandsTotal) + 1) * microdelay
			)),
			lagTime: lag
		)
	});
	fbins = DelayC.ar(
		in: BPF.ar(sig,allBpFreqs,bwr),
		maxdelaytime: 2.0,
		delaytime: macrodeltimes
	);
	XFade2.ar(
		sig,
		Mix(
			AllpassC.ar(
				in:fbins,
				maxdelaytime: 2.0,
				delaytime: microdeltimes,
				decaytime: microdecay)
		),
		VarLag.kr(outxfade)
	);
};
SynthDef(\fakeDiffusion__1, {|out|
	ReplaceOut.ar(out, SynthDef.wrap(synthfn, nil, [In.ar(out, 1)]));
}).add;
SynthDef(\fakeDiffusion__2, {|out, macrodecoherence=0, macrodelay=0.2, microdecoherence=(-0.25), microdelay=0.033, microdecay=0.2, outxfade=0.0, lag=0.5, splay=0.9|
	var sig = In.ar(out, 2);
	ReplaceOut.ar(out, [
		synthfn.value(
			sig[0],
			macrodecoherence: macrodecoherence,
			macrodelay: macrodelay,
			microdecoherence: microdecoherence,
			microdelay: microdelay,
			microdecay: microdecay,
			outxfade: outxfade,
			lag: lag),
		synthfn.value(
			sig[1],
			macrodecoherence: macrodecoherence*splay,
			macrodelay: macrodelay,
			microdecoherence: microdecoherence*splay,
			microdelay: microdelay,
			microdecay: microdecay,
			outxfade: outxfade,
			lag: lag),
	]);
}).dumpUGens.add;

state = ();
testsample = ~zamples +/+ "SupercolliderAuxiliary" +/+ "NS wind chimes 002-denoise-edit.aiff";
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
	/*~fakeDiffusion = (
		instrument: \fakeDiffusion__2,
		group: fxgroup,
		out: Bus.newFrom(outbus,0,1)
	).play;*/
	~fakeDiffusion = Synth(
		\fakeDiffusion__2, [
			\out, outbus,
			\macrodecoherence, 0.5,
			\inxfade, 0.7,
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
		\out, ~state.outbus,
		\dur, 1).play;
	~state = state;
};
)
(pitch: 5, group: ~state.voxgroup, out:~state.outbus).play;
~fakeDiffusion.set(\lag, 1);
~fakeDiffusion.set(\lag, 0.1);
~fakeDiffusion.set(\lag, 0);
~fakeDiffusion.set(\macrodelay, 2);
~fakeDiffusion.set(\macrodelay, 0.2);
~fakeDiffusion.set(\macrodecoherence, -1.0);
~fakeDiffusion.set(\macrodecoherence, 0.0);
~fakeDiffusion.set(\macrodecoherence, 1.0);
~fakeDiffusion.set(\microdecay, 2.0);
~fakeDiffusion.set(\microdecay, 0.1);
~fakeDiffusion.set(\microdelay, 0.2);
~fakeDiffusion.set(\microdelay, 0.01);
~fakeDiffusion.set(\microdecoherence, -1.0);
~fakeDiffusion.set(\microdecoherence, 0.0);
~fakeDiffusion.set(\microdecoherence, 1.0);
~fakeDiffusion.set(\microdecay, 0.1);
~fakeDiffusion.set(\microdecay, 1.0);
~fakeDiffusion.set(\microdecay, 10.0);
~fakeDiffusion.set(\splay, 1.0);
~fakeDiffusion.set(\splay, 0.0);
~fakeDiffusion.set(\splay, -1.0);
~fakeDiffusion.set(\outxfade, 1.0);
~fakeDiffusion.set(\outxfade, 0.7);
~fakeDiffusion.set(\outxfade, 0.0);
~fakeDiffusion.set(\outxfade, -0.7);
~fakeDiffusion.set(\outxfade, -1.0);
