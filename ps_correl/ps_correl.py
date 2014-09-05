"""
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
See also Vaelimaeki'st thesis: http://users.spa.aalto.fi/vpv/publications/vesa_phd.html
"""
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from ps_correl_analyze import sf_anal
from ps_correl_serve import serve
import threading
import argparse
import os.path

parser = argparse.ArgumentParser(description='Sound analysis server')
parser.add_argument('infile',
    # nargs='+',
    nargs='?',
    default=os.path.expanduser('~/src/sc/f_lustre/sounds/draingigm.aif'),
    # default=os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif'),
    help='file to analyse')
parser.add_argument('--bus-num', dest='bus_num', type=int,
    default=83,
    help='which SC bus should I set?')
parser.add_argument('--n', dest='n_results', type=int,
    default=6,
    help='how many results to return? (NB need 3 times this many buses)')
parser.add_argument('--rate', dest='rate', type=float,
    default=80.0,
    help='how many points per second will I classify?')
parser.add_argument('--port', dest='ps_correl_port', type=int,
    default=36000,
    help='port of scsynth to talk to (but monopolised by scsynth)')
parser.add_argument('--sc-synth-port', dest='sc_synth_port', type=int,
    default=57110,
    help='port of scsynth to talk to')
parser.add_argument('--sc-lang-port', dest='sc_lang_port', type=int,
    default=57120,
    help='port of scsynth to talk to (not currently used)')
parser.add_argument('--base-freq', dest='base_freq', type=float,
    default=440.0,
    help='base analysis frequency')
parser.add_argument('--steps', dest='n_steps', type=int,
    default=12,
    help='number of analysis frequencies')
parser.add_argument('--min-level', dest='min_level', type=float,
    default=0.001,
    help='min rms amplitude')

if __name__ == '__main__': 
    args = parser.parse_args()

    print "Analysing", args.infile
    wavdata = sf_anal(
        args.infile,
        chunk_rate=args.rate,
        n_steps=args.n_steps,
        base_freq=args.base_freq,
        min_level=args.min_level)

    print "Indexing..."
    # Startlingly, manhattan distance performs poorly.
    # euclidean is OK, or higher p-norms even.
    # should test the robustness of that against, e.g. pre-filtering
    #tree = BallTree(wavdata['all_corrs'].T, metric='minkowski', p=4) 
    tree = BallTree(wavdata['all_corrs'].T, metric='manhattan') # l1
    #tree = BallTree(wavdata['all_corrs'].T, metric='euclidean') # l2
    #tree = BallTree(wavdata['all_corrs'].T, metric='chebyshev') # l-infinity
    
    server = serve(tree, wavdata, args.ps_correl_port, args.n_results, args.sc_synth_port, args.bus_num)
    
    synth_server_thread = threading.Thread( target = server.serve_forever )
    synth_server_thread.start()

    raw_input("Serving analysis. Press Enter to quit...")
    server.close()
    
