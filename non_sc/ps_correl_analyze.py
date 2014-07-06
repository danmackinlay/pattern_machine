import numpy as np
from scipy.signal import filtfilt, decimate, iirfilter
from scipy.signal import filtfilt, decimate, iirfilter
from ps_correl_load import load_wav, load_non_wav
from ps_basicfilter import RC
from ps_correl_config import *

def high_passed(sr, wavdata, f=20.0):
    """remove the bottom few Hz (def 20Hz)"""
    rel_f = float(sr)/f
    b, a = RC(Wn=rel_f, btype='high')
    return filtfilt(b, a, wavdata)

def normalized(wavdata):
    wavdata -= wavdata.mean()
    wavdata *= 1.0/np.abs(wavdata).max()
    return wavdata

def sf_anal(sf_path):
    sr, wav = load_non_wav(sf_path)
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
    
    return dict(
        all_corrs=all_corrs,
        sample_times=sample_times,
        amp2=little_wav2,
    )
