import numpy as np
from scipy.signal import filtfilt, decimate, iirfilter
from ps_correl_load import load_wav, load_non_wav
from ps_basicfilter import RC
from ps_correl_config import *

def high_passed(sr, wavdata, f=20.0):
    """remove the bottom few Hz (def 20Hz)"""
    rel_f = 0.5 * f/float(sr)
    b, a = RC(Wn=rel_f, btype='high')
    return filtfilt(b, a, wavdata)

def normalized(wavdata):
    wavdata -= wavdata.mean()
    wavdata *= 1.0/np.abs(wavdata).max()
    return wavdata

def sf_anal(infile, chunk_rate=80.0, n_steps=12, base_freq=440.0, min_level=0.001, cutoff=None):
    min_sq_level = min_level**2
    if cutoff is None: cutoff = chunk_rate

    sr, wav = load_non_wav(infile)
    chunk_size = int(round(float(sr) / chunk_rate))
    wav = high_passed(sr, wav)
    wav2 = wav * wav
    freqs = 2**(np.linspace(0.0, n_steps, num=n_steps, endpoint=False)/n_steps) * base_freq

    amp2 = wav2
    rel_cutoff = 2.0/(float(sr)/cutoff)  # relative to nyquist freq, not samplerate
    b, a = RC(Wn=rel_cutoff)
    for i in xrange(4):
        amp2 = filtfilt(b, a, amp2)

    mask = amp2>min_sq_level
    little_amp2 = decimate(
        amp2, chunk_size, ftype='fir'
    )
    little_mask = mask[np.arange(0,little_amp2.size,1)*chunk_size]

    little_corrs = []
    for freq in freqs:
        # For now, offset is rounded to the nearest sample
        offset = int(round(float(sr)/freq))
        cov = np.zeros_like(wav)
        cov[:-offset] = wav[offset:]*wav[:-offset]
        # repeatedly filter; this is effectively an 8th-order lowpass now
        smooth_cov = cov
        for i in xrange(4):
            smooth_cov = filtfilt(b, a, smooth_cov)
        
        # technically the correlation should be taken wrt the harmonic mean of the variances at
        # the two times, but we assume autocorrelation lag << smooth time
        little_corrs.append(
            decimate(
                mask * smooth_cov/np.maximum(amp2, min_sq_level),
                chunk_size,
                ftype='fir' #FIR is needed to be stable at haptic rates
            )
        )
    
    
    all_corrs = np.vstack(little_corrs)
    sample_times = (np.arange(0,little_amp2.size,1)*chunk_size).astype(np.float)/sr

    #trim "too quiet" stuff
    all_corrs = all_corrs[:,np.where(little_mask)[0]]
    sample_times = sample_times[np.where(little_mask)[0]]
    little_amp2 = little_amp2[np.where(little_mask)[0]]
    
    return dict(
        all_corrs=all_corrs,
        sample_times=sample_times,
        amp=np.sqrt(little_amp2), #RMS amp is more usual
    )
