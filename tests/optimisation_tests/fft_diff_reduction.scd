GUI.qt;Server.default = s = ~serverboot.(\internal, \builtin);
/*
Summary:
FFT differences are just awful because low f bins are lies, and highly variable, esp for high bandwidth.
Work arounds?
BatUgens FrameCompare?
Weight frequencies?
Time blur frequencies? w/ PV_MagSmooth? http://sc3-plugins.git.sourceforge.net/git/gitweb.cgi?p=sc3-plugins/sc3-plugins;a=blob_plain;hb=refs/heads/master;f=source/MCLDUGens/sc/Help/PV_MagSmooth.html
Log differences?
*/

(fork {
	var	observedFftBuffer,targetFftBuffer, bothSignals,
		observedBus, targetBus, matchOut, examplesynthdef,
		template, comparer, candidate;
	observedFftBuffer = Buffer.alloc(s, 128);
	targetFftBuffer = Buffer.alloc(s, 128);
	bothSignals = Bus.new(\audio, 0, 2, s);
	observedBus = Bus.newFrom(bothSignals, 0, 1);
	targetBus = Bus.newFrom(bothSignals, 1, 1);
	matchOut = Bus.control(s, 1);
	s.sync;
	comparer = {|leak=0.1|
		var targetfftchain, obsfftchain, target, observed, localTargetFftBuffer, localObservedFftBuffer;

		target  = In.ar(targetBus, 1);
		observed = In.ar(observedBus, 1);

		// localTargetFftBuffer = LocalBuf.new(128,1);
		// localObservedFftBuffer = LocalBuf.new(128,1);

		localTargetFftBuffer = targetFftBuffer;
		localObservedFftBuffer = observedFftBuffer;

		targetfftchain = FFT(localTargetFftBuffer, target);
		obsfftchain = FFT(localObservedFftBuffer, observed);

		// Smear the FFT a little to avoid being trapped in bins
		// targetfftchain = PV_MagSmear(targetfftchain, 5);
		// obsfftchain = PV_MagSmear(obsfftchain, 5);

		leak = (leak**(ControlRate.ir.reciprocal));
		//replace me with a straight 1-pole:
		Integrator.kr(FFTDiffMags.kr(targetfftchain, obsfftchain) * (1-leak),  leak);
	}.play(target:s, addAction: \addToTail, outbus: matchOut);

	s.volume.volume = -20;

	examplesynthdef = SynthDef.new(
		\fft_dist_test_synth,
		{ |outbus=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5, amp=1.0, delay=0.0|
			Out.ar(outbus,
				DelayN.ar(
					Resonz.ar(
						Saw.ar(pitch, amp),
						ffreq,
						rq
					),
					delaytime: delay
				)
			);
		}
	).add;

	s.sync;

	template = Synth.new(
		\fft_dist_test_synth,
		[\outbus, targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \amp, 0.5, \delay, 0],
		target: s,
		addAction: \addToHead
	);
	candidate = Synth.new(
		\fft_dist_test_synth,
		[\outbus, observedBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \amp, 0.5, \delay, 0.0321207],
		target: s,
		addAction: \addToHead
	);

	Routine.new({
		while( true, {matchOut.get(_.postln);
		10.yield;})
	}).play;
	~bothSignals = bothSignals;
	~template = template;
	~candidate = candidate;
	~observedBus = observedBus;
	~observedFftBuffer = observedFftBuffer;
	~targetFftBuffer = targetFftBuffer;
	~candidate = candidate;
	~examplesynthdef = examplesynthdef;
	{
		~bothSignals.scope;
		FreqScope.new(busNum: ~observedBus);
	}.defer;
	//From the FFT Overview Help file, the best way of getting magnitudes
	// (should the buffer *happen* to have complex contents)
	~bufToComplex = {arg buf;
		var z, x;
		z = buf.clump(2).flop;
		z = [Signal.newFrom(z[0]), Signal.newFrom(z[1])];
		Complex(z[0], z[1]);
	};

})
(
	~observedFftBuffer.plot;
	~targetFftBuffer.plot;
)
//Now let's see how this goes with the two signals set to the same params
//Mags should be similar, but phases different.
(
~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \amp, 0.5);
)

//wait, then run
(
	~observedFftBuffer.loadToFloatArray(action: { |array|
		~obsfftbufasarraySame = array;
		~obsfftbufascomplexSame = ~bufToComplex.value(array);
	});
	~targetFftBuffer.loadToFloatArray(action: { |array|
		~targetfftbufasarraySame = array;
		~targetfftbufascomplexSame = ~bufToComplex.value(array);
	});
)
//Now plot
(
	//~obsfftbufplotSame = ~obsfftbufasarraySame.plot("raw obs");
	~obsfftbufplotcomplexSame = ~obsfftbufascomplexSame.magnitude.plot("obs magnitude - signals the same");
	//~targetfftbufplot = ~targetfftbufasarraySame.plot("raw target - signals the same");
	~targetfftbufplotcomplexSame = ~targetfftbufascomplexSame.magnitude.plot("target magnitude - signals the same");
	~diffmagbufplotSame = (~targetfftbufascomplexSame.magnitude-~obsfftbufascomplexSame.magnitude).abs.plot("diffmag - signals the same");
)
(
	(~targetfftbufascomplexSame.magnitude- ~obsfftbufascomplexSame.magnitude).abs.mean;
	(~targetfftbufascomplexSame-~obsfftbufascomplexSame).abs.mean;
	(~obsfftbufasarraySame-~targetfftbufasarraySame).abs.mean;
)
//Rinse and repeat, but now set the observered signal to have very different phases *and* mags
(
~candidate.set(\pitch, 27, \ffreq, 4800, \rq, 0.01, \amp, 0.5);
)
(
	~observedFftBuffer.loadToFloatArray(action: { |array|
		~obsfftbufasarrayDiff = array;
		~obsfftbufascomplexDiff = ~bufToComplex.value(array);
	});
	~targetFftBuffer.loadToFloatArray(action: { |array|
		~targetfftbufasarrayDiff = array;
		~targetfftbufascomplexDiff = ~bufToComplex.value(array);
	});
)
//Now plot
(
	//~obsfftbufplotDiff = ~obsfftbufasarrayDiff.plot("raw obs");
	~obsfftbufplotcomplexDiff = ~obsfftbufascomplexDiff.magnitude.plot("obs magnitude - signals different");
	//~targetfftbufplot = ~targetfftbufasarrayDiff.plot("raw target - signals different");
	~targetfftbufplotcomplexDiff = ~targetfftbufascomplexDiff.magnitude.plot("target magnitude - signals different");
	~diffmagbufplotDiff = (~targetfftbufascomplexDiff.magnitude-~obsfftbufascomplexDiff.magnitude).abs.plot("diffmag - signals different");
)
