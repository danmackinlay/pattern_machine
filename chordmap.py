# hand rolled ghetto chord similarity measure gives us a similarity matrix
# assumptions: 
# all notes are truncated saw waves
# all harmonics wrapped to the octave
# can construct a similarity by the inner product based on inner product of the the kernel-approximated vectors, then measuring ratio to mean inner norm; this is more-or-less the covariance of spectral energy
# also could track kernel width per-harmonic; is this principled? "feels" right, but we'll see.
# also, chould this be L1 instead of L2?

import numpy as np

N_HARMONICS = 16
KERNEL_WIDTH = 0.01 # less than this and they are the same note

energies = 1.0/(np.arange(N_HARMONICS)+1)
base_energies = 1.0/(np.arange(N_HARMONICS)+1)
base_harm_fs = np.arange(N_HARMONICS)+1
base_fundamentals = 2.0**(np.arange(12)/12.0)
# wrap harmonics
note_harmonics = (((np.outer(base_fundamentals, base_harm_fs)-1.0)%1.0)+1)

note_idx = np.arange(12, dtype="uint32")
cross_note_idx = np.vstack([np.repeat(note_idx,12), np.tile(note_idx,12)])
harm_idx = np.arange(N_HARMONICS)
cross_harm_idx = np.vstack([np.repeat(note_idx,N_HARMONICS), np.tile(note_idx,N_HARMONICS)])

def rect_kernel(nums, width=0.01):
    "returns rect kernel product of points [f1, a1, f2, a2]"
    return (abs(nums[0]-nums[2])<width)*nums[1]*nums[3]

def note_product(n1, n2, kernel_fn=rect_kernel):
    harm_fs = np.vstack([
        note_harmonics[n1,:][cross_harm_idx[0]],
        energies[cross_harm_idx[0]],
        note_harmonics[n2,:][cross_harm_idx[1]],
        energies[cross_harm_idx[1]],
    ])
    return np.apply_along_axis(kernel_fn, 0, harm_fs).sum()

chord_ind = np.arange(4096, dtype="uint32")
# poor man's bit-unpack. Why can't I find a python function that does this?

chord_mask = np.array([
    np.bitwise_and(
        np.right_shift(chord_ind, i),
        1
    ) for i in note_idx
]).transpose()

def make_chord(i, notes):
    chord_harm_fs = note_harmonics[notes,:].flatten()
    chord_harm_energies = np.tile(base_energies, len(notes))

