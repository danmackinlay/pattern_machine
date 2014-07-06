"""
rapidly analyse a bunch of files for a particular autocorrelation profile

For fractional sample delay, we could do cubic interpolation, or polyphase filtering:
http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html

TODO: kNN search on this data set:
http://scikit-learn.org/stable/modules/neighbors.html#ball-tree
TODO: OSC query server - basic PyOSC should be OK, given low IO load.
https://bitbucket.org/arjan/txosc/wiki/Home

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK? since it will select for similar spectral balances)
In which case, should normalising be relative to filtered, or total, amplitude?

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: How do we detect inharmonic noise? Convolved with shuffled, or enveloped pink/white noise? This would have the bonus of reducing need for high pass
TODO: adaptive masking noise floor
TODO: live server bus setting (time index, estimated amplitude, file index)
TODO: live server synth triggering
TODO: live client feedback
TODO: serialise analysis to disk ? (not worth it right now; analysis speed is negligible even unoptimised)
TODO: handle updates per OSC
TODO: confirm this RC function has correct frequency parameterization
TODO: handle multiple files
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
TODO: dimension reduction
TODO: estimate variance of analysis; e.g. higher when amp is low, or around major changes
TODO: search ALSO on variance, to avoid spurious transient onset matches, or to at least allow myself to have such things
TODO: switch to Erik De Castro Lopo's libsamplerate to do the conversions; scipy's decimate could be better; there exist nice wrappers eg https://github.com/cournape/samplerate
"""

import os.path
import sys
import numpy as np
from scipy.signal import filtfilt, decimate, iirfilter
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree
from OSC import OSCClient, OSCMessage, OSCServer

from ps_basicfilter import RC
from ps_correl_load import load_wav, load_non_wav

OUTPUT_BASE_PATH = os.path.normpath("./")
#CORR_PATH = os.path.join(OUTPUT_BASE_PATH, 'corr.h5')

#SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')
SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/draingigm.aif')
TIME_QUANTUM = 1.0/80.0 #Analyse at ca 80Hz
BASEFREQ = 440.0
N_STEPS = 12
MIN_LEVEL = 0.001 #ignore stuff less than -60dB
MIN_MS_LEVEL = MIN_LEVEL**2
SC_SERVER_PORT = 57110

def high_passed(sr, wavdata, f=20.0):
    """remove the bottom few Hz (def 20Hz)"""
    rel_f = float(sr)/f
    b, a = RC(Wn=rel_f, btype='high')
    return filtfilt(b, a, wavdata)

def normalized(wavdata):
    wavdata -= wavdata.mean()
    wavdata *= 1.0/np.abs(wavdata).max()
    return wavdata


sr, wav = load_non_wav(SF_PATH)
blocksize = int(round(sr * TIME_QUANTUM))
wav = high_passed(sr, wav)
wav = normalized(wav)
wav2 = wav * wav
freqs = 2**(np.linspace(0.0, N_STEPS, num=N_STEPS, endpoint=False)/N_STEPS) * BASEFREQ

smooth_wav2 = wav2
rel_f = 2.0/(float(sr)*TIME_QUANTUM)  # relative to nyquist freq, not samplerate
b, a = RC(Wn=rel_f)
for i in xrange(4):
    smooth_wav2 = filtfilt(b, a, smooth_wav2)

mask = smooth_wav2>MIN_MS_LEVEL
little_wav2 = decimate(
    smooth_wav2, blocksize, ftype='fir'
)
little_mask = mask[np.arange(0,little_wav2.size,1)*blocksize]

little_corrs = []
for freq in freqs:
    # For now, offset is rounded to the nearest sample; we don't use e.g polyphase delays 
    offset = int(round(float(sr)/freq))
    cov = np.zeros_like(wav)
    cov[:-offset] = wav[offset:]*wav[:-offset]
    # repeatedly filter; this is effectively and 8th-order lowpass now
    smooth_cov = cov
    for i in xrange(4):
        smooth_cov = filtfilt(b, a, smooth_cov)
    
    little_corrs.append(
        decimate(
            mask * smooth_cov/np.maximum(smooth_wav2, MIN_MS_LEVEL),
            blocksize,
            ftype='fir' #FIR is needed to be stable at haptic rates
        )
    )

all_corrs = np.vstack(little_corrs)
sample_times = (np.arange(0,little_wav2.size,1)*blocksize).astype(np.float)/sr

#trim "too quiet" stuff
all_corrs = all_corrs[:,np.where(little_mask)[0]]
sample_times = sample_times[np.where(little_mask)[0]]
little_wav2 = little_wav2[np.where(little_mask)[0]]

tree = BallTree(all_corrs.T, metric='euclidean')


client = OSCClient()
client.connect( ("localhost", SC_SERVER_PORT) )

def user_callback(path, tags, args, source):
    print path, tags, args, source
    # looks like 
    #/transect iifffffffffffff [1001, 1, -0.6750487089157104, -0.5806915163993835, -0.49237504601478577, -0.4095775783061981, -0.3318118751049042, -0.2586633563041687, -0.18976180255413055, -0.12478849291801453, -0.06346030533313751, -0.005534188821911812, 0.049216993153095245, 0.10099353641271591, 0.12387804687023163] ('127.0.0.1', 57110)
    node = args[0]
    idx = args[1]
    lookup = args[3:] #ignores the amplitude?
    indices = tree.query(lookup, k=10, return_distance=False)
    print indices
    indices = list(*sample_times[indices])
    # could send server bus messages and client info messages
    client.send(OSCMessage("/c_setn", 1, indices[0]))

# distances, indices = tree.query([1,1,1,1,1,1,1,1,1,1,1,1], k=10)
server = OSCServer(("localhost", 36000), client=client, return_port=57110)
server.addMsgHandler("/transect", user_callback )
client.send( OSCMessage("/notify", 1 ) ) #subscribe to server stuff

#client.send( OSCMessage("/quit") )

