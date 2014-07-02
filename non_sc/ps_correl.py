"""
rapidly ananlyse a bunch of files for a particular autocorrelation profile

For fractional sample delay, we can do cubic interpolation, or polyphase filtering:

http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html

NN search on this data set:
http://scikit-learn.org/stable/modules/neighbors.html#ball-tree
over osc... - basic PyOSC should be OK, given low IO load.
https://bitbucket.org/arjan/txosc/wiki/Home

To consider: should we highpass as the base f of the signal to reduce spurious bass "correlation"? (or is that OK?, since it will select for similar spectral balances)

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...

TODO: How do we detect inharmonic noise? Convolved with shuffled, or enveloped pink/white noise? This would have the bonus of reducing need for high pass
TODO: index and decimate by time, (e.g. 50ms) not sample index (accordingly, remove quiet sections from index)
TODO: make amplitude smoothing dependent on this time quantum
TODO: adaptive masking noise floor
TODO: live server bus setting (time index, estimated amplitude, file index)
TODO: live server synth triggering
TODO: live client feedback
TODO: serialise analysis to disk ? (not worth it right now; analysis speed is 100+:1 before optimisation)
TODO: handle updates per OSC
TODO: confirm this RC function has correct frequency parameterization
TODO: handle multiple files
TODO: decimation is to neareset whole number ratio and therefore does not respect time exactly.
"""

import os.path
import sys
import numpy as np
import scipy.io.wavfile
from scipy.signal import filtfilt, decimate, iirfilter
import wave
import tempfile
import subprocess
import math
import tables
from math import exp, log
from sklearn.neighbors import NearestNeighbors, KDTree, BallTree

OUTPUT_BASE_PATH = os.path.normpath("./")
CORR_PATH = os.path.join(OUTPUT_BASE_PATH, 'corr.h5')

#SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')
SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/draingigm.aif')
TIME_QUANTUM = 0.025 #Anlayise at ca 40Hz
BASEFREQ = 440.0
N_STEPS = 12
MIN_LEVEL = 0.001 #ignore stuff less than -60dB
MIN_MS_LEVEL = MIN_LEVEL**2

def RC(Wn, btype='low', dtype=np.float64):
     """ old-fashioned minimal filter design, if you don't want this modern bessel nonsense """
     epsilon = np.finfo(dtype).eps
     f = Wn/2.0 # shouldn't this be *2.0?
     x = exp(-2*np.pi*f)
     if btype == 'low':
         b, a = np.zeros(2), np.zeros(2)
         b[0] = 1.0 - x - epsilon #filter instability
         b[1] = 0.0
         a[0] = 1.0
         a[1] = -x
     elif btype == 'high':
         b, a = np.zeros(2), np.zeros(2)
         b[0] = (1.0+x)/2.0
         b[1] = -(1.0+x)/2.0
         a[0] = 1.0
         a[1] = -x
     else:
         raise ValueError, "btype must be 'low' or 'high'"
     return b,a

def load_wav(filename):
    try:
        wavedata=scipy.io.wavfile.read(filename)
        samplerate=int(wavedata[0])
        smp=wavedata[1]*(1.0/32768.0)
        if len(smp.shape)>1: #convert to mono
            smp=(smp[:,0]+smp[:,1])*0.5
        return (samplerate,smp)
    except:
        print "Error loading wav: "+filename
        return None

def high_passed(sr, wavdata, f=20.0):
    """remove the bottom few Hz (def 20Hz)"""
    rel_f = float(sr)/f
    b, a = RC(Wn=rel_f, btype='high')
    return filtfilt(b, a, wavdata)

def normalized(wavdata):
    wavdata -= wavdata.mean()
    wavdata *= 1.0/np.abs(wavdata).max()
    return wavdata
    
def load_non_wav(filename):
    newfilename = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.check_call([
        "sox",
        filename,
        newfilename])
    wav = load_wav(newfilename)
    os.unlink(newfilename)
    return wav

sr, wav = load_non_wav(SF_PATH)
blocksize = sr * TIME_QUANTUM
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

little_corrs = []
for freq in freqs:
    # For now, offset is rounded to the nearest sample; we don't use e.g polyphase delays 
    offset = int(round(float(sr)/freq))
    cov = np.zeros_like(wav)
    cov[:-offset] = wav[offset:]*wav[:-offset]
    rel_f = freq/(float(sr)/2.0) # relative to nyquist freq, not samplerate
    b, a = RC(Wn=rel_f)
    smooth_cov = cov
    local_smooth_wav2 = wav2
    # repeatedly filter; this is effectively and 8th-order lowpass now
    for i in xrange(4):
        smooth_cov = filtfilt(b, a, smooth_cov)
        local_smooth_wav2 = filtfilt(b, a, smooth_wav2)
    
    little_corrs.append(
        decimate(
            mask * smooth_cov/np.maximum(local_smooth_wav2, MIN_MS_LEVEL),
            int(round(blocksize)),
            ftype='fir' #FIR is needed to be stable at haptic rates
        )
    )

little_wav2 = decimate(
    mask * smooth_wav2, int(round(blocksize)), ftype='fir'
)

all_corr = np.vstack(little_corrs)

filt = None
# filt = tables.Filters(complevel=5)

with tables.open_file(CORR_PATH, 'w') as table_out_handle:
    table_out_handle.create_carray('/','v_freqs',
        atom=tables.Float32Atom(),
        shape=freqs.shape,
        title="freqs",
        filters=filt)[:] = freqs
    table_out_handle.create_carray('/','v_corrs',
        atom=tables.Float32Atom(), shape=all_corr.shape,
        title="corrs",
        filters=filt)[:] = all_corr
    table_out_handle.create_carray('/','v_mag',
        atom=tables.Float32Atom(), shape=all_corr.shape,
        title="mag",
        filters=filt)[:] = little_wav2

tree = BallTree(all_corr.T, metric='euclidean')
distances, indices = tree.query([1,1,1,1,1,1,1,1,1,1,1,1], k=10)