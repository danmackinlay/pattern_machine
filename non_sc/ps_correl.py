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
import wave
import tempfile
import subprocess

SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')

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

freq = 440.0
offset = round( float(sr)/freq)
corr = wav[offset:]*wav[:-offset]
ny_cutoff = freq/(float(sr)/2.0)
