"""
rapidly ananlyse a bunch of files for a particular autocorrelation profile

see http://docs.scipy.org/doc/scipy/reference/tutorial/signal.html#b-splines for fast interpolation

see also scipy.signal.periodogram and scipy.signal.welch, praps signal.lfilter and/or signa.correlate

http://www.tau.ac.il/~kineret/amit/scipy_tutorial/
http://hub.hku.hk/bitstream/10722/46311/1/71706.pdf?accept=1
polyphase filtering is the right keyword
http://cnx.org/content/m11657/latest/
http://mechatronics.ece.usu.edu/yqchen/dd/index.html
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

SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')
BLOCKSIZE = 64 #downsample analysis by this many samples

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
wav2 = wav * wav

freq = 440.0
offset = round(float(sr)/freq)
cov = np.zeros_like(wav)
cov[offset:] = wav[offset:]*wav[:-offset]
#ratio = math.exp(math.log(WAVELEN_DECAY)/offset)
rel_f = freq/(float(sr)/2.0) # relative to nyquist freq, not samplerate
a, b = iirfilter(N=1, Wn=rel_f, btype='lowpass', ftype='butter') # or ftype='bessel'?
# inital conditions:
zi = lfilter_zi(a, b) # if we wish to initialize the filter to non-zero val
smooth_cov, zf = lfilter(a, b, cov, zi=zi*0)
smooth_wav2, zf = lfilter(a, b, wav2, zi=zi*0)
small_corr =  decimate(smooth_cov/np.maximum(smooth_wav2, 0.000001), BLOCKSIZE, ftype='iir')
