Rapidly analyse audio for a particular autocorrelation profile

To consider: should we highpass as the base f of the signal to reduce
spurious bass "correlation"? (or is that OK? since it will select for
similar spectral balances) In which case, should normalising be relative
to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g.
7/11/13-tone steps?

Also, what loss function? negative correlation is more significant than
positive, for example...


Todo
--------

Handle general feature search using librosa. Candidate features:

-    [chromagram](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.chromagram)
-   [pitch](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.ifptrack)
    and some prejection thereof ([alt](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.piptrack))
-   [MFCC](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.mfcc)
    and [deltas
    thereof](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.delta)
-   [aggregate stats
    thereof](http://bmcfee.github.io/librosa/librosa.html#librosa.feature.sync)
-   [onsets](http://bmcfee.github.io/librosa/librosa.html#module-librosa.onset)
-   general [segmentation](http://bmcfee.github.io/librosa/librosa.html#module-librosa.segment)
-   Also [harmonic-percussive decomposition](http://bmcfee.github.io/librosa/librosa.html#librosa.decompose.hpss)
    could be REALLY fun

-   search using pytables instead of BallTree; gives us more dynamic
    axial scaling. (*both* could be fun) 
-   Better yet, search on a PCA
    (or other low-dim representation) of the data 
-   alternative ratios- (more) enharmonic 
-   ratio ideas - consider Farey sequence:
    <http://www.johndcook.com/blog/2010/10/20/best-rational-approximation/>
-   project pitch shifts that would align spectra correctly 
-   possibly this would require quadratic peak interpolation - <http://www.dsprelated.com/dspbooks/sasp/Quadratic_Interpolation_Spectral_Peaks.html>
-   Comb filters instead of autocorrelation? This would model have
    quadratic maxima, but sharper would be better; this could be a
    combination FB+FF, or an extra layer of FF. Advantage: linear,
    well-behaved z-transform. | H(e\^{j omega}) | = sqrt{(1 + alpha\^2) + 2
    alpha cos(omega K)} 
-   <http://yehar.com/blog/?p=368>
-   <https://en.wikipedia.org/wiki/Convolution_theorem#Functions_of_a_discrete_variable>...\_sequences
-   Hartley transfrom? <https://en.wikipedia.org/wiki/Hartley_transform>

More general transforms:
<https://en.wikipedia.org/wiki/Integral_transform#Table_of_transforms>
<https://en.wikipedia.org/wiki/Singular_integral_operators_of_convolution_type>

-   median filters for bands 
-   never return times at start and end of the file 
-   cache analysis to disk? 
-   How do we detect noise? Correlated with shuffled, or enveloped pink/white noise? 
-   search ALSO on variance, to avoid spurious transient onset matches 
-   search ALSO on gradient 
-   delts and double deltas
-   more conservative pregain management to avoid onset clipping 
-   include grain size in search and search based on that (tricky but safer) 
-   restrict search based on amplitude range
-   restrict search based on certainty range (this would require us to
    actually have a model), e.g. higher when amp is low, or around major
    changes, or estimated from sample variance (this should be taken wrt the
    innovation process) 
-   handle multiple files 
-   handle multiple clients through e.g. nodeid 
-   adaptive masking noise floor
-   plot spectrograms and sanity check against analysis data 
-   work out how to suppress "no handler" warnings 
-   switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg <https://github.com/cournape/samplerate> 
-   treat smoothing or other free parameters (or neighbourhood size) as a model-selection problem?
    AIC or cross-validation? 
-   decimation is to neareset whole number ratio and therefore does not respect time exactly. For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
<http://www.tau.ac.il/~kineret/amit/scipy_tutorial/>
<http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1>
<http://cnx.org/content/m11657/latest/>
<http://mechatronics.ece.usu.edu/yqchen/dd/index.html>
<http://cnx.org/content/m15490/latest/> See also Vaelimaeki's thesis:
<http://users.spa.aalto.fi/vpv/publications/vesa_phd.html>

<http://network.bepress.com/engineering/electrical-and-computer-engineering/signal-processing/>

