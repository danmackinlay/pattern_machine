Instr.new( //toy listener comparing signal with a 500Hz sine
  "phenosynth.listeners.default",
  {|in, evalPeriod = 1|
    LagUD.ar(
      Convolution.ar(in, SinOsc.ar(500), 1024, 0.5).abs,
      evalPeriod/8,
      evalPeriod
    );
  }, [
    \audio,
    \evalperiod
  ], \fitness
);
Instr.new(
  "phenosynth.listeners.conv_comparator",
  { |in, evalPeriod = 1, reference|
    A2K.kr(LagUD.ar(
      Convolution.ar(in, reference, 1024, 0.5).abs,
      evalPeriod/8,
      evalPeriod
    ));
    }, [
      \audio,
      \evalperiod,
      \audio
    ], \fitness
);

Instr.new(
  "phenosynth.listeners.fft_comparator",
  {|in, evalPeriod = 1, reference, active=0, t_reset=0|
  var othersig, testsig, comparison, integral, sigamp, oamp, 
    sigfft, offt, sigbufplay, obufplay, fftdiff,
    resynth;
  
  testsig  = LeakDC.ar(in);
  othersig = LeakDC.ar(reference);
  
  // Take a wideband FFT of the signals since we're interested in time-domain features rather than freq precision
  // (use buffers of ~64 or 128 size - NB 32 is too small - kills the server)
  sigfft = FFT(LocalBuf(2048), testsig);
  offt =   FFT(LocalBuf(2048), othersig);
  
  // Smear the FFT a little to avoid being trapped in bins
  sigfft = PV_MagSmear(sigfft, 5);
    offt = PV_MagSmear(  offt, 5);

  comparison = FFTDiffMags.kr(sigfft, offt);

  // Divide by the server's control rate to scale the output nicely
  comparison = comparison / ControlRate.ir;
  
  // Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
  Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
});

