GUI.qt;
Server.default = s = ~serverboot.(\internal, \builtin);
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
	
	examplesynthdef = SynthDef.new(
		\fft_dist_test_synth,
		{ |out=0, gate=0, t_reset=0, pitch=800, ffreq=500, rq=0.5, gain=1.0, delay=0.0|
			Out.ar(out,
				DelayN.ar(
					Resonz.ar(
						Saw.ar(pitch, gain),
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
		[\out, targetBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5, \delay, 0],
		target: s,
		addAction: \addToHead
	);
	candidate = Synth.new(
		\fft_dist_test_synth,
		[\out, observedBus, \gate, 1, \pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5, \delay, 0.0321207],
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
})
(
	~observedFftBuffer.plot;
	~targetFftBuffer.plot;
)
(
	//From the FFT Overview Help file, the best way of getting magnitudes
	// (should the buffer *happen* to have complex contents)
	~bufToComplex = {arg buf;
	Ê Ê var z, x;
	Ê Ê z = buf.clump(2).flop;
	Ê Ê z = [Signal.newFrom(z[0]), Signal.newFrom(z[1])];
	Ê Ê Complex(z[0], z[1]);
	};
)
//Now let's see how this goes with the two signals set to the same params
//Mags should be similar, but phases different.
(
~candidate.set(\pitch, 400, \ffreq, 600, \rq, 0.3, \gain, 0.5);
)

//wait, then run
(
	~observedFftBufferSame.loadToFloatArray(action: { |array|
		~obsfftbufasarraySame = array;
		~obsfftbufascomplexSame = ~bufToComplex.value(array);
	});
	~targetFftBufferSame.loadToFloatArray(action: { |array| 
		~targetfftbufasarraySame = array;
		~obsfftbufascomplexSame = ~bufToComplex.value(array);
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
~candidate.set(\pitch, 27, \ffreq, 4800, \rq, 0.01, \gain, 0.5);
)
(
	~observedFftBufferSame.loadToFloatArray(action: { |array|
		~obsfftbufasarraySame = array;
		~obsfftbufascomplexSame = ~bufToComplex.value(array);
	});
	~targetFftBufferSame.loadToFloatArray(action: { |array| 
		~targetfftbufasarraySame = array;
		~obsfftbufascomplexSame = ~bufToComplex.value(array);
	});
)
//Now plot
(
	//~obsfftbufplotSame = ~obsfftbufasarraySame.plot("raw obs");
	~obsfftbufplotcomplexSame = ~obsfftbufascomplexSame.magnitude.plot("obs magnitude - signals different");
	//~targetfftbufplot = ~targetfftbufasarraySame.plot("raw target - signals different");
	~targetfftbufplotcomplexSame = ~targetfftbufascomplexSame.magnitude.plot("target magnitude - signals different");
	~diffmagbufplotSame = (~targetfftbufascomplexSame.magnitude-~obsfftbufascomplexSame.magnitude).abs.plot("diffmag - signals different");
)
