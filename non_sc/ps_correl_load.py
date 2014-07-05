import tempfile
import subprocess
import os
import os.path
import scipy.io.wavfile

def load_wav(filename):
    try:
        wavedata=scipy.io.wavfile.read(filename)
        samplerate=int(wavedata[0])
        smp=wavedata[1]*(1.0/32768.0)
        if len(smp.shape)>1: #convert to mono
            smp=(smp[:,0]+smp[:,1])*0.5
        return (samplerate,smp)
    except Exception, e:
        e.filename = filename
        raise e

def load_non_wav(filename):
    newfilename = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.check_call([
        "sox",
        filename,
        newfilename])
    wav = load_wav(newfilename)
    os.unlink(newfilename)
    return wav