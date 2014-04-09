/*
Originally based on MCLD's example MCLD_Genetic tests, though the
resemblance is rapidly diminishing.

Here I keep all the "Compare" synths, that compare one signal, somehow or
other, against a reference/template signal

Thesee shoudl now be regarded as untested, since i did nasty little hacks
to make these all into distances, as opposed to similarity measurea.
Ideally this means that two identical signals have a distance of zero,
but let's look at that a little later. */

PSBasicCompareSynths {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*makeComparer { |name, func, lags|
		/* A listen synthdef factory, complete with graceful accumulation.
		Be careful with those bus arguments.
		Comparers made with this method are channel-blind -
		the input channels are mixed down to mono.*/
		(1..4).do({|targetChan| (1..4).do({|obsChan|
			var channame;
			channame = "%__%_%".format(name,obsChan,targetChan);

			SynthDef.new(channame, {
				|observedbus, targetbus=0, outbus=0, active=1, t_reset=0, i_leak=0.5|
				var observedsig, targetsig, comparison, integral;

				targetsig  = Mix.new(In.ar(targetbus, targetChan));
				observedsig = Mix.new(In.ar(observedbus, obsChan));

				//targetbus.poll(0.1, \targetbus);
				//observedbus.poll(0.1, \observedbus);

				/*Calculate a leak coefficient to discount fitness over time,
				 presuming the supplied value is a decay level _per_second_. (Half
				 life is less convenient, since it doesn't admit -infinity easily) */
				i_leak = (i_leak**(ControlRate.ir.reciprocal)*(i_leak>0));//.poll(0.1, \leak);

				comparison = SynthDef.wrap(func, lags, [targetsig, observedsig]);

				/*
				A 1 pole filter with decay rate per second given by i_leak.
				When t_reset briefly hits nonzero, the integrator drains. That
				functionality is not actually used here.
				*/
				integral = Integrator.kr(comparison * active * (1-i_leak), if(t_reset>0, 0, i_leak));

				Out.kr(outbus, integral);
			}).add;
		});});
	}
	*loadSynthDefs {
		// Try and match amplitude envelope against a target signal
		this.makeComparer(\ps_judge_amp_distance, {
			|targetsig, observedsig|
			var targetamp, oamp;

			targetamp = Amplitude.kr(targetsig);
			oamp = Amplitude.kr(observedsig);

			(targetamp.max(0.00001)/(oamp.max(0.00001))).log.abs;
		});

		// Try and match pitch envelope against a template signal
		this.makeComparer(\ps_judge_pitch_distance, {
			|targetsig, observedsig|
			var targetpitch, targethaspitch, opitch, ohaspitch;

			# targetpitch, targethaspitch = Pitch.kr(targetsig);
			# opitch, ohaspitch = Pitch.kr(observedsig);

			(targetpitch.max(0.1)/(opitch.max(0.1))).log.abs;
		});
		// Try and match pitch and amplitude envelope against a template signal
		this.makeComparer(\ps_judge_pitchamp_distance, {
			|targetsig, observedsig|
			var targetpitch, targethaspitch, targetamp, opitch, ohaspitch, oamp, nanfitness, nanness;
			var eps = 0.00001;

			# targetpitch, targethaspitch = Pitch.kr(targetsig);
			# opitch, ohaspitch = Pitch.kr(observedsig);
			targetamp = Amplitude.kr(targetsig);
			oamp = Amplitude.kr(observedsig);
			(targetamp.max(0.00001)/(oamp.max(0.00001))).log.abs +
				(targetpitch.max(0.1)/(opitch.max(0.1))).log.abs;
		});
		/* Try and match pitch envelope against a template signal - but using
		 ZeroCrossing*/
		this.makeComparer(\ps_judge_pitch_distance_zc, {
			|targetsig, observedsig|
			var targetpitch, opitch;

			targetpitch = A2K.kr(ZeroCrossing.ar(targetsig));
			opitch = A2K.kr(ZeroCrossing.ar(observedsig));

			(targetpitch.max(0.1)/(opitch.max(0.1))).log.abs;
		});

		/* Try and match the FFT of the individual against some "template" signal
		- typically an audio sample.
		NB - this uses a custom MCLD Ugen, available in the SC3-plugins project
		*/
		this.makeComparer(\ps_judge_fft_wide_distance, {
			|targetsig, observedsig|
			var targetfft, offt, bfr1, bfr2;
			/* Take a wideband FFT of the signals since we're interested in
			 time-domain features rather than freq precision
			*/

			bfr1 = LocalBuf.new(128,1);
			bfr2 = LocalBuf.new(128,1);

			targetfft = FFT(bfr1, targetsig);
			offt = FFT(bfr2, observedsig);

			// Smear the FFT a little to avoid being trapped in bins
			// targetfft = PV_MagSmear(targetfft, 5);
			// offt = PV_MagSmear(offt, 5);

			FFTDiffMags.kr(targetfft, offt);
		});
		/* Try and match the FFT of the individual against some "template" signal
		- typically an audio sample.
		NB - this uses a custom MCLD Ugen, available in the SC3-plugins project
		*/
		this.makeComparer(\ps_judge_fft_narrow_distance, {
			|targetsig, observedsig|
			var targetfft, offt, bfr1, bfr2;
		   /* Take a narrowband FFT and match timbre precisely*/

			bfr1 = LocalBuf.new(512,1);
			bfr2 = LocalBuf.new(512,1);

			targetfft = FFT(bfr1, targetsig);
			offt = FFT(bfr2, observedsig);

			// Smear the FFT a little to avoid being trapped in bins
			targetfft = PV_MagSmear(targetfft, 5);
			offt = PV_MagSmear(offt, 5);

			FFTDiffMags.kr(targetfft, offt);
		});

		/*Convolution-based comparison. Amplitude-blind.*/
		this.makeComparer(\ps_judge_convolution_norm_distance, {
			|targetsig, observedsig|
			targetsig = Normalizer.ar(targetsig);
			observedsig = Normalizer.ar(observedsig);
			Amplitude.kr(Convolution.ar(targetsig, observedsig, framesize: 512)).max(0.00001).reciprocal;
		});
		/*Convolution-based comparison that attempts to match amplitudes*/
		this.makeComparer(\ps_judge_convolution_distance, {
			|targetsig, observedsig|
			var amptarget, ampobs, amplo, amphi, obsHigher;
			amptarget = Amplitude.kr(targetsig).max(0.0001);
			ampobs = Amplitude.kr(observedsig).max(0.0001);
			Amplitude.kr(Convolution.ar(targetsig, observedsig, framesize: 512)) / (
				amptarget*ampobs
			).log;
		});
		/*Cepstral-based comparison that attempts to match amplitudes*/
		this.makeComparer(\ps_judge_cepstral_distance, {
			|targetsig, observedsig|
			var targetfft, offt, targetcep, ocep, ffbfr1, ffbfr2, cepbfr1, cepbfr2;

			ffbfr1 = LocalBuf.new(2048,1);
			ffbfr2 = LocalBuf.new(2048,1);
			cepbfr1 = LocalBuf.new(1024,1);
			cepbfr2 = LocalBuf.new(1024,1);

			targetfft = FFT(ffbfr1, targetsig);
			offt =   FFT(ffbfr2, observedsig);
			targetcep = Cepstrum(cepbfr1, targetfft);
			ocep =   Cepstrum(cepbfr2, offt);
			
			FFTDiffMags.kr(targetcep, ocep);
		});
		this.makeComparer(\ps_judge_cepstral_norm_distance, {
			|targetsig, observedsig|
			var targetfft, offt, targetcep, ocep, ffbfr1, ffbfr2, cepbfr1, cepbfr2;

			ffbfr1 = LocalBuf.new(2048,1);
			ffbfr2 = LocalBuf.new(2048,1);
			cepbfr1 = LocalBuf.new(1024,1);
			cepbfr2 = LocalBuf.new(1024,1);

			targetsig = Normalizer.ar(targetsig);
			observedsig = Normalizer.ar(observedsig);

			targetfft = FFT(ffbfr1, targetsig);
			offt =   FFT(ffbfr2, observedsig);
			targetcep = Cepstrum(cepbfr1, targetfft);
			ocep =   Cepstrum(cepbfr2, offt);

			FFTDiffMags.kr(targetcep, ocep);
		});
		/*MFCC-based comparison
		assumes 44.1/48Khz. Should check that, eh?
		This gives you rough timbral similarities, but is a crap pitch tracker.
		It will, e.g., prefer signals with similar bandwidths over signals with similar pitches.*/
		this.makeComparer(\ps_judge_mfcc_distance, {
			|targetsig, observedsig|
			var targetfft, offt, targetMFCCoef, oMFCCoef, bfr1, bfr2;

			//should be 2048 for 96kHz, 1024 for 44/48kHz.
			bfr1 = LocalBuf.new(1024,1);
			bfr2 = LocalBuf.new(1024,1);

			targetfft = FFT(bfr1, targetsig);
			offt =   FFT(bfr2, observedsig);

			//rms difference - should log diff? or abs diff?
			targetMFCCoef = MFCC.kr(targetfft, numcoeff:42);
			oMFCCoef = MFCC.kr(offt, numcoeff:42);

			(targetMFCCoef - oMFCCoef).squared.sum;
		});
		/*MFCC-based comparison with extra amplitude-match weighting*/
		this.makeComparer(\ps_judge_mfcc_amp_distance, {
			|targetsig, observedsig|
			var targetfft, offt, targetMFCCoef, oMFCCoef, bfr1, bfr2, ampdist;
			var targetamp, oamp, totaldist, polltrig;

			//should be 2048 for 96kHz, 1024 for 44/48kHz.
			bfr1 = LocalBuf.new(1024,1);
			bfr2 = LocalBuf.new(1024,1);

			targetfft = FFT(bfr1, targetsig);
			offt = FFT(bfr2, observedsig);

			//rms difference - should log diff? or abs diff?
			targetMFCCoef = MFCC.kr(targetfft, numcoeff:42);
			oMFCCoef = MFCC.kr(offt, numcoeff:42);

			targetamp = Amplitude.kr(targetsig)+0.0000001;
			oamp = Amplitude.kr(observedsig)+0.0000001;
			//check out these fairly arbitrary scaling factors:
			ampdist = (((targetamp.log)-(oamp.log)).abs*0.25);

			totaldist = (targetMFCCoef - oMFCCoef).squared.sum + ampdist;
			/*
			//Running this debuggey thing reveals that an empty
			//mfcc thing has coefficients of all 0.25 (?)
			polltrig = Impulse.kr(0.1)*(totaldist<0.01);
			Poll.kr(
				trig: polltrig,
				in: oMFCCoef,
				label: 42.collect("obs" ++ _),
				trigid: (1..42)
			);
			Poll.kr(
				trig: polltrig,
				in: targetMFCCoef,
				label: 42.collect("target" ++ _),
				trigid: (1..42)
			);
			*/
			totaldist;
		});
		/* For debugging, we sometimes wish to return the input.
		This makes no sense as an actual fitness function, however.*/
		this.makeComparer(\ps_judge_return_observed, {
			|targetsig, observedsig|
			A2K.kr(observedsig);
		});
	}
}
