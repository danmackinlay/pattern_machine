Server.default = s = ~serverboot.(\internal, \builtin);
(
fork {
	SynthDef.new(\fft_dist_test_comp, {
		|target, observed, bfrtarget, bfrobs, out, leak=0.1|
		var targetfft, offt, integral;
		target  = In.ar(target, 1);
		observed = In.ar(observed, 1);

		// bfrtarget = LocalBuf.new(128,1);
		// bfrobs = LocalBuf.new(128,1);

		targetfft = FFT(bfrtarget, target);
		offt = FFT(bfrobs, observed);

		// Smear the FFT a little to avoid being trapped in bins
		// targetfft = PV_MagSmear(targetfft, 5);
		// offt = PV_MagSmear(offt, 5);
		leak = (leak**(ControlRate.ir.reciprocal));
		//replace me with a straight 1-pole:
		integral = Integrator.kr(FFTDiffMags.kr(targetfft, offt) * (1-leak),  leak);

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

	~bothSignals = Bus.new(\audio, 0, 2, s);
	~observedBus = Bus.newFrom(~bothSignals, 0, 1);
	~observedFftBuffer = Buffer.alloc(s, 128);
	~targetBus = Bus.newFrom(~bothSignals, 1, 1);
	~targetFftBuffer = Buffer.alloc(s, 128);
	~matchOut = Bus.control(s, 1);
	~voxgroup = Group.head(s);
	[~observedBus, ~matchOut, ~voxgroup, ~targetBus].postln;
	~outgroup = Group.tail(s);
	s.sync;
	~template = Synth.new(\ps_reson_saw, [\out, ~targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5], target: ~voxgroup);
	~candidate = Synth.new(\ps_reson_saw, [\out, ~observedBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.5, \gain, 0.5], target: ~voxgroup);
	~comparer = Synth.new(\ps_judge_fft_distance_wide, [\observedbus, ~observedBus, \targetbus, ~targetBus, \out, ~matchOut, \leak, 0, \bfrtarget, ~targetFftBuffer, \bfrobs, ~observedFftBuffer], target: ~outgroup);

	Routine.new({
		while( true, {~matchOut.get(_.postln);
		1.yield;})
	}).play;
 	{
		FreqScope.new(busNum:~observedBus);
	}.defer;
	{
		~bothSignals.scope;
	}.defer;
	~observedFftBuffer.plot;
	~targetFftBuffer.plot;
}
)
~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5);
~candidate.set(\pitch, 27, \ffreq, 1200, \rq, 0.1, \gain, 0.5);