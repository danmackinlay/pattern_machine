
Rapidly analyse a bunch of files for a particular autocorrelation profile

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK? since it will select for similar spectral balances)
In which case, should normalising be relative to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: search using pytables instead of BallTree; gives us more dynamic axial scaling. (*both* could be fun)
TODO: mine MIDI files for spectral co-ocurrence data and see if this allows us to predict "matching" spectra
TODO: alternative ratios- (more) enharmonic
TODO: ratio ideas - consider Farey sequence: http://www.johndcook.com/blog/2010/10/20/best-rational-approximation/
TODO: project pitch shifts that would align spectra correctly
TODO: possibly this would require quadratic peak interpolation - http://www.dsprelated.com/dspbooks/sasp/Quadratic_Interpolation_Spectral_Peaks.html
TODO: Comb filters instead of autocorrelation? This would model have quadratic maxima, but sharper would be better; this could be a combination FB+FF, or an extra layer of FF. Advantage: linear, well-behaved z-transform. \ | H(e^{j \omega}) | = \sqrt{(1 + \alpha^2) + 2 \alpha \cos(\omega K)}
TODO: Does the Hilbert transform do what I want?
https://en.wikipedia.org/wiki/Hilbert_transform#Relationship_with_the_Fourier_transform
http://yehar.com/blog/?p=368
https://en.wikipedia.org/wiki/Convolution_theorem#Functions_of_a_discrete_variable..._sequences
Hartley transfrom? https://en.wikipedia.org/wiki/Hartley_transform
more generally
https://en.wikipedia.org/wiki/Integral_transform#Table_of_transforms https://en.wikipedia.org/wiki/Singular_integral_operators_of_convolution_type
TODO: median filters for bands
TODO: never return times at start and end of the file
TODO: cache analysis to disk?
TODO: How do we detect noise? Correlated with shuffled, or enveloped pink/white noise? 
TODO: search ALSO on variance, to avoid spurious transient onset matches
TODO: search ALSO on gradient
TODO: dimension reduction through PCA
TODO: dimension reduction through MDS
TODO: more conservative pregain management to avoid onset clipping
TODO: include grain size in search and search based on that (tricky but safer)
TODO: restrict search based on amplitude range
TODO: restrict search based on certainty range (this would require us to actually have a model), e.g. higher when amp is low, or around major changes, or estimated from sample variance (this should be taken wrt the innovation process)
TODO: handle multiple files
TODO: handle multiple clients through e.g. nodeid
TODO: adaptive masking noise floor
TODO: plot spectrograms and sanity check against analysis data
TODO: work out how to suppress "no handler" warnings
TODO: switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg https://github.com/cournape/samplerate
TODO: treat smoothing or other free parameters (or neighbourhood size) as a model-selection problem? AIC or cross-validation?
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html
http://cnx.org/content/m15490/latest/
See also Vaelimaeki's thesis: http://users.spa.aalto.fi/vpv/publications/vesa_phd.html
Note: registering two correlograms to find optimal alignment isa computatinoal tractable problem - there is only one paramter once the two are fit to some fucntional basis, and its derivative is simple (ish), up to function interpolation. So I can align based on this. Is it worth it? Probably only if i can find a descriptor such that i can search for similar correlograms, THEN register them. 
Watch out for boundary conditions.
Also note, i can restrict transforms to within an octave
Keywords: Procrustes method, rigid body solution. 
Although i don't think I'll bother reading those right now; I think i just worked out a newton's method solution with good ol' pen'n'paper.

should think about decent basis functions (rbf? fourier? b-spline?)

http://pythonhosted.org//librosa/tutorial.html#quickstart
http://pythonhosted.org//librosa/librosa.html#module-librosa.feature


librosa.feature.piptrack
librosa.feature.ifptrack