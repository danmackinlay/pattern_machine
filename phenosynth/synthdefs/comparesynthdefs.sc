/*
Originally based on MCLD's example MCLD_Genetic tests, though the
resemblance is rapidly diminishing.

Here I keep all the "Compare" synths, that compare one signal, somehoe or
other, against a reference/template signal
*/

PSBasicCompareSynths {
	*initClass{
		StartUp.add({
			this.classInit;
		});
	}
	*classInit{
		/* I give my *actual* class initialisation the name of classInit, for ease of consistently initialising classes
		*/
		this.loadSynthDefs;
	}
	*loadSynthDefs {
		// This judge is one of the simplest I can think of (for demo purposes) 
		// - evaluates closeness of pitch to a reference value (800 Hz).

		// Try and match amplitude envelope against a template signal
		SynthDef.new(\_ga_judge_ampmatch, {		|testbus, templatebus=0, out=0, active=0, t_reset=0|
			var othersig, testsig, comparison, integral, sigamp, oamp, 
				resynth;
			
			testsig  = In.ar(testbus, 1);
			othersig = In.ar(templatebus, 1);
			
			sigamp = Amplitude.kr(testsig);
			oamp = Amplitude.kr(othersig);
			
			comparison = (sigamp - oamp).abs;
			
			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;
			
			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
			
			Out.kr(out, integral);
		}).add;


		// Try and match pitch envelope against a template signal
		SynthDef.new(\_ga_judge_pitchmatch, {		|testbus, templatebus=0, out=0, active=0, t_reset=0|
			var othersig, testsig, comparison, integral, sigpitch, opitch, sighaspitch, ohaspitch,
				resynth;
			
			testsig  = In.ar(testbus, 1);
			othersig = In.ar(templatebus, 1);
							
			# sigpitch, sighaspitch = Pitch.kr(testsig);
			# opitch, ohaspitch = Pitch.kr(othersig);
			
			comparison = (sigpitch - opitch).abs * 0.1;
			
			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;
			
			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
			
			Out.kr(out, integral);
		}).add;
		
		// Try and match pitch envelope against a template signal - but using ZeroCrossing
		SynthDef.new(\_ga_judge_pitchmatch_zc, {		|testbus, templatebus=0, out=0, active=0, t_reset=0|
			var othersig, testsig, comparison, integral, sigpitch, opitch, 
				resynth;
			
			testsig  = In.ar(testbus, 1);
			othersig = In.ar(templatebus, 1);
							
			sigpitch = A2K.kr(ZeroCrossing.ar(testsig));
			opitch = A2K.kr(ZeroCrossing.ar(othersig));
			
			comparison = (sigpitch - opitch).abs * 0.1;
			
			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;
			
			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
			
			Out.kr(out, integral);
		}).add;
		// Try and match the FFT of the individual against some "template" signal - typically an audio sample.
		// NB - this uses a CUSTOM UGEN, available from http://www.mcld.co.uk/supercollider/
		SynthDef.new(\_ga_judge_fftmatch, {|testbus, templatebus=0, out=0, active=0, t_reset=0|
			var othersig, testsig, comparison, integral, sigamp, oamp, 
				sigfft, offt, sigbufplay, obufplay, fftdiff,
				resynth, bfr1, bfr2;
			bfr1 = LocalBuf.new(128,1);
			bfr2 = LocalBuf.new(128,1);
			testsig  = LeakDC.ar(In.ar(testbus, 1));
			othersig = LeakDC.ar(In.ar(templatebus, 1));
			
			// Take a wideband FFT of the signals since we're interested in time-domain features rather than freq precision
			// (use buffers of ~64 or 128 size - NB 32 is too small - kills the server)
			sigfft = FFT(bfr1, testsig);
			offt =   FFT(bfr2, othersig);
			
			// Smear the FFT a little to avoid being trapped in bins
			sigfft = PV_MagSmear(sigfft, 5);
			  offt = PV_MagSmear(  offt, 5);

			comparison = FFTDiffMags.kr(sigfft, offt);

			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;
			
			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
			
			Out.kr(out, integral);
		}).add;

		// Really simple SynthDef to play a buffer when triggered
		SynthDef.new(\_ga_just_playbuf, {		|bufnum, out=0, t_trig=0|
			Out.ar(out, /* SinOsc.ar(440,0,0.1) + */ PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), t_trig));
		});

		// Like FFT but with normaliser
		SynthDef.new(\_ga_judge_fftmatch_norm, {		|testbus, templatebus=0, out=0, active=0, t_reset=0|
			var othersig, testsig, comparison, integral, sigamp, oamp, 
				sigfft, offt, sigbufplay, obufplay, fftdiff,
				resynth, bfr1, bfr2;
			bfr1 = LocalBuf.new(128,1);
			bfr2 = LocalBuf.new(128,1);
			
			testsig  = Normalizer.ar(LeakDC.ar(In.ar(testbus, 1)));
			othersig = Normalizer.ar(LeakDC.ar(In.ar(templatebus, 1)));
			
			// Take a wideband FFT of the signals since we're interested in time-domain features rather than freq precision
			// (use buffers of ~64 or 128 size - NB 32 is too small - kills the server)
			sigfft = FFT(bfr1, testsig);
			offt =   FFT(bfr2, othersig);
			
			comparison = FFTDiffMags.kr(sigfft, offt);

			// Divide by the server's control rate to scale the output nicely
			comparison = comparison / ControlRate.ir;
			
			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
			
			Out.kr(out, integral);
		}).add;
	}
}
