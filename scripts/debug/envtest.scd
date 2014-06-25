SynthDef.new(\windowtest, {
	|out, freq=440, freqB=660,
	lforate=0.21|
	var phaseA, trigA, trigB, envA, envB, sigA, sigB;
	phaseA = LFSaw.kr(lforate);
	trigA = phaseA < 0;
	trigB = phaseA >= 0;
	envA = CentredApprox.halfCos(phaseA);
	envB = CentredApprox.halfCos((phaseA+1).wrap2(1));
	sigA = PMOsc.ar(carfreq: freq, modfreq:freq*1.25, pmindex:0.2, mul:envA);
	sigB = PMOsc.ar(carfreq: freqB, modfreq:freqB*1.5, pmindex:0.15, mul:envB);
	Out.ar(outbus, sigA + sigB);
}).add;

Synth(\windowtest).scope;