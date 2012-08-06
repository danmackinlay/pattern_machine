/*
Originally based on MCLD's example MCLD_Genetic tests, though the
resemblance is rapidly diminishing.

Here I keep all the "Compare" synths, that compare one signal, somehow or
other, against a reference/template signal
*/

PSBasicCompareSynths {
	*initClass{
		StartUp.add({
			this.classInit;
		});
	}
	*classInit{
		/* I give my *actual* class initialisation the name of classInit,
		for ease of consistently initialising classes
		*/
		this.loadSynthDefs;
	}
	*makeComparer { |name, func, lags|
		/* A listen synthdef factory, complete with graceful accumulation.
		Be careful with those bus arguments.*/
		SynthDef.new(name, {
			|observedbus, targetbus=0, out=0, active=1, t_reset=0, i_leak=0.5|
			var observedsig, targetsig, comparison, integral;

			// targetsig  = LeakDC.ar(In.ar(targetbus, 1));
			// observedsig = LeakDC.ar(In.ar(observedbus, 1));
			targetsig  = In.ar(targetbus, 1);
			observedsig = In.ar(observedbus, 1);

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

			Out.kr(out, integral);
		}).add;
	}
	*loadSynthDefs {
		// Try and match amplitude envelope against a target signal
		this.makeComparer(\ps_judge_amp_distance, {
			|targetsig, observedsig|
			var targetamp, oamp;

			targetamp = Amplitude.kr(targetsig);
			oamp = Amplitude.kr(observedsig);

			(1- (targetamp - oamp).abs).max(0);
		});

		// Try and match pitch envelope against a template signal
		this.makeComparer(\ps_judge_pitch_distance, {
			|targetsig, observedsig|
			var targetpitch, targethaspitch, opitch, ohaspitch;

			# targetpitch, targethaspitch = Pitch.kr(targetsig);
			# opitch, ohaspitch = Pitch.kr(observedsig);

			(100 - ((targetpitch - opitch).abs * 0.1)).max(0);
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

			nanfitness = ((targetpitch+eps)/(opitch+eps)).log.abs + ((targetamp+eps)/(oamp+eps)).log.abs;
			//nanness = CheckBadValues.kr
			nanfitness;
		});
		/* Try and match pitch envelope against a template signal - but using
		 ZeroCrossing*/
		this.makeComparer(\ps_judge_pitch_distance_zc, {
			|targetsig, observedsig|
			var targetpitch, opitch;

			targetpitch = A2K.kr(ZeroCrossing.ar(targetsig));
			opitch = A2K.kr(ZeroCrossing.ar(observedsig));

			(100 - ((targetpitch - opitch).abs * 0.1)).max(0);
		});

		/* Try and match the FFT of the individual against some "template" signal
		- typically an audio sample.
		NB - this uses a  CUSTOM MCLD UGEN, available in the SC3-plugins project
		*/
		this.makeComparer(\ps_judge_fft_distance_wide, {
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
		NB - this uses a CUSTOM MCLD UGEN, available in the SC3-plugins project.
		*/
		this.makeComparer(\ps_judge_fft_distance_narrow, {
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
		this.makeComparer(\ps_judge_convolution_norm, {
			|targetsig, observedsig|
			targetsig = Normalizer.ar(targetsig);
			observedsig = Normalizer.ar(observedsig);

			Amplitude.kr(Convolution.ar(targetsig, observedsig, framesize: 512));
		});
		/*Convolution-based comparison that attempts to match amplitudes*/
		this.makeComparer(\ps_judge_convolution, {
			|targetsig, observedsig|
			var amptarget, ampobs, amplo, amphi, obsHigher;
			amptarget = Amplitude.kr(targetsig);
			ampobs = Amplitude.kr(observedsig);
			obsHigher = (ampobs>amptarget);
			amplo = Select.kr(obsHigher, [ampobs, amptarget]);
			amphi = Select.kr(obsHigher, [amptarget, ampobs]);
			/*amptarget.poll(0.1, \ampta);
			ampobs.poll(0.1, \ampob);
			obsHigher.poll(0.1, \obsHi);
			amplo.poll(0.1, \amplo);
			amphi.poll(0.1, \amphi);*/
			Amplitude.kr(Convolution.ar(targetsig, observedsig, framesize: 512)) * (
				amphi/(amplo+0.0000001)
			);
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

			// // Smear the FFT a little to avoid being trapped in bins
			// targetcep = PV_MagSmear(targetcep, 5);
			//   ocep = PV_MagSmear(  ocep, 5);

			FFTDiffMags.kr(targetcep, ocep);
		});
		this.makeComparer(\ps_judge_cepstral_distance_norm, {
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

			// // Smear the FFT a little to avoid being trapped in bins
			// targetcep = PV_MagSmear(targetcep, 5);
			//   ocep = PV_MagSmear(  ocep, 5);

			FFTDiffMags.kr(targetcep, ocep);
		});
		/*MFCC-based comparison
		assumes 44.1/48Khz. Should check that, eh?
		This gives you rough timbral similarities, but is a crap pitch tracker.
		It will, e.g., prefer signals with similar bandwidths over signals with similar pitches.*/
		this.makeComparer(\ps_judge_mfcc_distance, {
			|targetsig, observedsig|
			var targetfft, offt, sigcepstrum, ocepstrum, bfr1, bfr2;

			//should be 2048 for 96kHz, 1024 for 44/48kHz.
			bfr1 = LocalBuf.new(1024,1);
			bfr2 = LocalBuf.new(1024,1);

			targetfft = FFT(bfr1, targetsig);
			offt =   FFT(bfr2, observedsig);

			//rms difference - should log diff? or abs diff?
			sigcepstrum = MFCC.kr(targetfft, numcoeff:42);
			ocepstrum = MFCC.kr(offt, numcoeff:42);

			(sigcepstrum - ocepstrum).squared.sum;
		});
		/*For debugging, we sometimes wish to return the input.
		This makes no sense as an actual fitness function, however.*/
		this.makeComparer(\ps_judge_return_observed, {
			|targetsig, observedsig|
			A2K.kr(observedsig);
		});
	}
}
