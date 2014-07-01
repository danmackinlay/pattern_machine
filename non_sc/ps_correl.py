"""
rapidly ananlyse a bunch of files for a particular autocorrelation profile

see http://docs.scipy.org/doc/scipy/reference/tutorial/signal.html#b-splines for fast interpolation

see also scipy.signal.periodogram and scipy.signal.welch, praps signal.lfilter and/or signa.correlate

http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
polyphase filtering is the right keyword
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html

NN searrch on this data set:
http://scikit-learn.org/stable/modules/neighbors.html#ball-tree
over osc... - baisic PyOSC should be OK? or gevented server?

To consider: should we highpass as the base f of  the signal to reduce spurious bass "correlation". (or is that OK?, since it will select for similar spectral balances)

Also to consider: random frequencies? if so, how many? Or, e.g. 7/11/13-tone steps?  

Also, what loss function? negative correlation is more significant than positive, for example...
Should we even normalise to [-1,1]? That might be an alternative to bass filtering.

How do we detect inharmonic noise?
"""

import os.path
import sys
import numpy as np
import scipy.io.wavfile
from scipy.signal import lfilter, decimate, lfilter_zi, iirfilter
import wave
import tempfile
import subprocess
import math
import tables

OUTPUT_BASE_PATH = os.path.normpath("./")
CORR_PATH = os.path.join(OUTPUT_BASE_PATH, 'corr.h5')

SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')
BLOCKSIZE = 64 #downsample analysis by this many samples
BASEFREQ = 440
N_STEPS = 12

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

def normalized(wavdata):
    wavdata -= wavdata.mean()
    wavdata *= 1.0/np.abs(wavdata).max()
    return wavdata
    
def load_non_wav(filename):
    #could really use some 
    newfilename = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.check_call([
        "sox",
        filename,
        newfilename])
    wav = load_wav(newfilename)
    os.unlink(newfilename)
    return wav

sr, wav = load_non_wav(SF_PATH)
wav = normalized(wav)
wav2 = wav * wav
freqs = 2**(np.linspace(0.0, N_STEPS, num=N_STEPS, endpoint=False)/N_STEPS) * BASEFREQ

corrs = []

for freq in freqs:
    offset = round(float(sr)/freq)
    cov = np.zeros_like(wav)
    cov[offset:] = wav[offset:]*wav[:-offset]
    #purely for initialisation
    cov[:offset] = cov[offset:2*offset]
    #ratio = math.exp(math.log(WAVELEN_DECAY)/offset)
    rel_f = freq/(float(sr)/2.0) # relative to nyquist freq, not samplerate
    b, a = iirfilter(N=3, Wn=rel_f, btype='lowpass', ftype='butter') # or ftype='bessel'?
    # inital conditions:
    zi = lfilter_zi(b, a) # if we wish to initialize the filter to non-zero val
    smooth_cov, zf = lfilter(b, a, cov, zi=zi*cov[:offset].mean())
    smooth_wav2, zf = lfilter(b, a, wav2, zi=zi*wav2[:offset].mean())
    corrs.append(decimate(smooth_cov/np.maximum(smooth_wav2, 0.000001), BLOCKSIZE, ftype='iir'))

all_corr = np.vstack(corrs)


filt = None
#    filt = tables.Filters(complevel=5)

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