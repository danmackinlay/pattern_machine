Server.default = s = ~serverboot.(\internal, \builtin);
(
fork {
	var	observedFftBuffer,targetFftBuffer, bothSignals,
		observedBus, targetBus, matchOut, voxgroup,
		template, comparer, candidate, outgroup,
		comparer;
	observedFftBuffer = Buffer.alloc(s, 128);
	targetFftBuffer = Buffer.alloc(s, 128);
	bothSignals = Bus.new(\audio, 0, 2, s);
	observedBus = Bus.newFrom(bothSignals, 0, 1);
	targetBus = Bus.newFrom(bothSignals, 1, 1);
	matchOut = Bus.control(s, 1);
	voxgroup = Group.head(s);
	outgroup = Group.tail(s);
	[observedBus, matchOut, voxgroup, targetBus].postln;
	s.sync;
	SynthDef.new(\fft_dist_test_comp, {
		|target, observed, out, leak=0.1|
		var targetfftchain, obsfftchain, integral;
		target  = In.ar(target, 1);
		observed = In.ar(observed, 1);

		// targetFftBuffer = LocalBuf.new(128,1);
		// observedFftBuffer = LocalBuf.new(128,1);

		targetfftchain = FFT(observedFftBuffer, target);
		obsfftchain = FFT(targetFftBuffer, observed);

		// Smear the FFT a little to avoid being trapped in bins
		// targetfftchain = PV_MagSmear(targetfftchain, 5);
		// obsfftchain = PV_MagSmear(obsfftchain, 5);
		leak = (leak**(ControlRate.ir.reciprocal));
		//replace me with a straight 1-pole:
		integral = Integrator.kr(FFTDiffMags.kr(targetfftchain, obsfftchain) * (1-leak),  leak);

		Out.kr(out, integral);
	}).add;
	
	SynthDef.new(
		\fft_dist_test_synth,
		{ |out=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5, gain=1.0|
			Out.ar(out, Resonz.ar(
				Saw.ar(pitch, gain),
				ffreq,
				rq
			));
		}
	).add;

	s.sync;
	template = Synth.new(\ps_reson_saw, [\out, targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5], target: voxgroup);
	candidate = Synth.new(\ps_reson_saw, [\out, observedBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.5, \gain, 0.5], target: voxgroup);
	comparer = Synth.new(\ps_judge_fft_distance_wide, [\observedbus, observedBus, \targetbus, targetBus, \out, matchOut, \leak, 0], target: outgroup);

	Routine.new({
		while( true, {~matchOut.get(_.postln);
		1.yield;})
	}).play;
 	{
		~bothSignals.scope;
		FreqScope.new(busNum:~observedBus);
		observedFftBuffer.plot;
		targetFftBuffer.plot;
	}.defer;
})
observedFftBuffer.loadToFloatArray(action: { arg array; a = array; {a.plot;}.defer;});
targetFftBuffer.plot;

~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5);
~candidate.set(\pitch, 27, \ffreq, 4800, \rq, 0.01, \gain, 0.5);