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
			targetsig  = LeakDC.ar(In.ar(observedbus, 1));
			observedsig = LeakDC.ar(In.ar(targetbus, 1));

			/*Calculate a leak coefficient to discount fitness over time,
			 presuming the supplied value is a decay rate _per_second_. (Half
			 life is less convenient, since it doesn't admit infinity easily) */
			i_leak = i_leak**(ControlRate.ir.reciprocal);
			//sanity check that.
			//Poll.kr(Impulse.kr(10), DC.kr(i_leak), \leak);
			
			comparison = SynthDef.wrap(func, lags, [targetsig, observedsig]);
			
			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;

			/* Default coefficient of i_leak = no leak. When t_reset briefly hits
			 nonzero, the integrator drains.*/
			integral = Integrator.kr(comparison * active * (1-i_leak), if(t_reset>0, 0, i_leak));

			Out.kr(out, integral);
		}).add;
	}
	*loadSynthDefs {
		// First, a utility synth:
		
		// Really simple SynthDef to play a buffer when triggered
		SynthDef.new(\_ga_just_playbuf, {|bufnum, out=0, t_trig=0|
			Out.ar(out, /* SinOsc.ar(440,0,0.1) + */ PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), t_trig));
		});
			
		// Try and match amplitude envelope against a template signal
		this.makeComparer(\_ga_judge_ampmatch, {
			|targetsig, observedsig|
			var targetamp, oamp;
			
			targetamp = Amplitude.kr(targetsig);
			oamp = Amplitude.kr(observedsig);

			(1- (targetamp - oamp).abs).max(0);
		});

		// Try and match pitch envelope against a template signal
		this.makeComparer(\_ga_judge_pitchmatch, {
			|targetsig, observedsig|
			var targetpitch, targethaspitch, opitch, ohaspitch;
			
			# targetpitch, targethaspitch = Pitch.kr(targetsig);
			# opitch, ohaspitch = Pitch.kr(observedsig);
			
			(100 - ((targetpitch - opitch).abs * 0.1)).max(0);
		});
		// Try and match pitch and amplitude envelope against a template signal
		this.makeComparer(\_ga_judge_pitchampmatch, {
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
		this.makeComparer(\_ga_judge_pitchmatch_zc, {
			|targetsig, observedsig|
			var targetpitch, opitch;
			
			targetpitch = A2K.kr(ZeroCrossing.ar(targetsig));
			opitch = A2K.kr(ZeroCrossing.ar(observedsig));
			
			(100 - ((targetpitch - opitch).abs * 0.1)).max(0);
		});		
		
		/* Try and match the FFT of the individual against some "template" signal
		- typically an audio sample.
		NB - this uses a CUSTOM UGEN, available in the SC3-plugins project 
		This appears to evaluate to, e.g. 0.002, for unmatched signals, and 0 for identical ones
		That is, it reports difference in magnitude as the name implies.
		For most purposes it is too fragile a comparison to be useful.*/
		this.makeComparer(\_ga_judge_fftmatch, {
			|targetsig, observedsig|
			var targetfft, offt, bfr1, bfr2;
			
			bfr1 = LocalBuf.new(128,1);
			bfr2 = LocalBuf.new(128,1);

			/* Take a wideband FFT of the signals since we're interested in
			 time-domain features rather than freq precision
			 (use buffers of ~64 or 128 size - NB 32 is too small - kills the
				 server) */
			targetfft = FFT(bfr1, targetsig);
			offt =   FFT(bfr2, observedsig);
			
			// Smear the FFT a little to avoid being trapped in bins
			targetfft = PV_MagSmear(targetfft, 5);
			  offt = PV_MagSmear(  offt, 5);
			
			FFTDiffMags.kr(targetfft, offt);
		});

		/*Convolution-based comparison
		this should be smarter about comparative amplitudes, which will require me to know FFT delay,
		but is probably the best thing in my armoury.*/
		this.makeComparer(\_ga_judge_convolution, {
			|targetsig, observedsig|
			var targetfft, offt, bfr1, bfr2;
			
			targetsig = Normalizer.ar(targetsig);
			observedsig = Normalizer.ar(observedsig);
			
			Amplitude.kr(Convolution.ar(targetsig, observedsig, framesize: 512));
		});
		/*MFCC-based comparison
		assumes 44.1/48Khz. Should check that, eh?
		This gives you rough timbral similarities, but is a crap pitch tracker.
		It will, e.g., prefer signals with similar bandwidths over signals with similar pitches.*/
		this.makeComparer(\_ga_judge_mfccmatch, {
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
	}
}
