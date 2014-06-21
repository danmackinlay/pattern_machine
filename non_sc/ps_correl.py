"""
rapidly ananlyse a bunch of files for a particular autocorrelation profile

see http://docs.scipy.org/doc/scipy/reference/tutorial/signal.html#b-splines for fast interpolation

"""

import sys
from numpy import *
import scipy.io.wavfile
import wave

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


