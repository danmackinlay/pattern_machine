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
			|testbus, templatebus=0, out=0, active=1, t_reset=0, i_leak=0.5|
			var othersig, testsig, comparison, integral, sigamp, oamp, 
				sigfft, offt, sigbufplay, obufplay, fftdiff, resynth, bfr1, bfr2;
			testsig  = LeakDC.ar(In.ar(testbus, 1));
			othersig = LeakDC.ar(In.ar(templatebus, 1));

			/*Calculate a leak coefficient to discount fitness over time,
			 presuming the supplied value is a decay rate _per_second_. (Half
			 life is less convenient, since it doesn't admit infinity easily) */
			i_leak = i_leak**(ControlRate.ir.reciprocal);
			//sanity check that.
			//Poll.kr(Impulse.kr(10), DC.kr(i_leak), \leak);
			
			comparison = SynthDef.wrap(func, lags, [testsig, othersig]);
			
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
			|testsig, othersig|
			var sigamp, oamp;
			
			sigamp = Amplitude.kr(testsig);
			oamp = Amplitude.kr(othersig);

			(1- (sigamp - oamp).abs).max(0);
		});

		// Try and match pitch envelope against a template signal
		this.makeComparer(\_ga_judge_pitchmatch, {
			|testsig, othersig|
			var sigpitch, sighaspitch, opitch, ohaspitch;
			
			# sigpitch, sighaspitch = Pitch.kr(testsig);
			# opitch, ohaspitch = Pitch.kr(othersig);
			
			(100 - ((sigpitch - opitch).abs * 0.1)).max(0);
		});
		// Try and match pitch and amplitude envelope against a template signal
		this.makeComparer(\_ga_judge_pitchampmatch, {
			|testsig, othersig|
			var sigpitch, sighaspitch, sigamp, opitch, ohaspitch, oamp, nanfitness, nanness;
			var eps = 0.00001;
			
			# sigpitch, sighaspitch = Pitch.kr(testsig);
			# opitch, ohaspitch = Pitch.kr(othersig);
			sigamp = Amplitude.kr(testsig);
			oamp = Amplitude.kr(othersig);
			
			nanfitness = ((sigpitch+eps)/(opitch+eps)).log.abs + ((sigamp+eps)/(oamp+eps)).log.abs;
			//nanness = CheckBadValues.kr
			nanfitness;
		});
		/* Try and match pitch envelope against a template signal - but using
		 ZeroCrossing*/
		this.makeComparer(\_ga_judge_pitchmatch_zc, {
			|testsig, othersig|
			var sigpitch, opitch;
			
			sigpitch = A2K.kr(ZeroCrossing.ar(testsig));
			opitch = A2K.kr(ZeroCrossing.ar(othersig));
			
			(100 - ((sigpitch - opitch).abs * 0.1)).max(0);
		});		
		
		/* Try and match the FFT of the individual against some "template" signal
		- typically an audio sample.
		NB - this uses a CUSTOM UGEN, available in the SC3-plugins project 
		This appears to evaluate to, e.g. 0.002, for unmatched signals, and 0 for identical ones
		That is, it reports difference in magnitude as the name implies.
		For most purposes it is too fragile a comparison to be useful.*/
		this.makeComparer(\_ga_judge_fftmatch, {
			|testsig, othersig|
			var sigfft, offt, bfr1, bfr2;
			
			bfr1 = LocalBuf.new(128,1);
			bfr2 = LocalBuf.new(128,1);

			/* Take a wideband FFT of the signals since we're interested in
			 time-domain features rather than freq precision
			 (use buffers of ~64 or 128 size - NB 32 is too small - kills the
				 server) */
			sigfft = FFT(bfr1, testsig);
			offt =   FFT(bfr2, othersig);
			
			// Smear the FFT a little to avoid being trapped in bins
			sigfft = PV_MagSmear(sigfft, 5);
			  offt = PV_MagSmear(  offt, 5);
			
			FFTDiffMags.kr(sigfft, offt);
		});

		/*Convolution-based comparison
		this should be smarter about comparative amplitudes, which will require me to know FFT delay,
		but is probably the best thing in my armoury.*/
		this.makeComparer(\_ga_judge_convolution, {
			|testsig, othersig|
			var sigfft, offt, bfr1, bfr2;
			
			testsig = Normalizer.ar(testsig);
			othersig = Normalizer.ar(othersig);
			
			Amplitude.kr(Convolution.ar(testsig, othersig, framesize: 512));
		});
		/*MFCC-based comparison
		assumes 44.1/48Khz. Should check that, eh?
		This gives you rough timbral similarities, but is a crap pitch tracker.
		It will prefer signals with similar bandwidths over signals with similar pitches.*/
		this.makeComparer(\_ga_judge_mfccmatch, {
			|testsig, othersig|
			var sigfft, offt, sigcepstrum, ocepstrum, bfr1, bfr2;
			
			//should be 2048 for 96kHz
			bfr1 = LocalBuf.new(1024,1);
			bfr2 = LocalBuf.new(1024,1);

			sigfft = FFT(bfr1, testsig);
			offt =   FFT(bfr2, othersig);
			
			//rms difference - should log diff? or abs diff?
			sigcepstrum = MFCC.kr(sigfft, numcoeff:42);
			ocepstrum = MFCC.kr(offt, numcoeff:42);
			
			(sigcepstrum - ocepstrum).squared.sum;
		});		
	}
}
