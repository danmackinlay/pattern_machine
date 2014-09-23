# hand rolled ghetto chord similarity measure gives us a similarity matrix
# assumptions: 
# all notes are harmonically truncated saw waves
# all harmonics wrapped to the octave
# can construct a similarity by the inner product based on inner product of the the kernel-approximated vectors, then measuring ratio to mean inner norm; this is more-or-less the covariance of spectral energy
# also could track kernel width per-harmonic; is this principled? "feels" right, but we'll see.
# also, chould this be L1 instead of L2?
# could I optimised by creating a basis of notes (yes)

import numpy as np
from scipy.spatial.distance import squareform, pdist
from math import sqrt

N_HARMONICS = 16
KERNEL_WIDTH = 0.01 # less than this and they are the same note

def cross_p_idx(n1, n2):
    "poor-mans's nditer, written offline when i coulnd't look it up"
    return np.vstack([
        np.tile(np.arange(n1),n2),
        np.repeat(np.arange(n2), n1),
    ])

def bit_unpack(i):
    # little-endian bit-unpacking
    bits = [int(s) for s in bin(i)[2:]]
    bits.reverse()
    return bits

energies = 1.0/(np.arange(N_HARMONICS)+1)
base_energies = 1.0/(np.arange(N_HARMONICS)+1)
base_harm_fs = np.arange(N_HARMONICS)+1
base_fundamentals = 2.0**(np.arange(12)/12.0)
# wrap harmonics
note_harmonics = (((np.outer(base_fundamentals, base_harm_fs)-1.0)%1.0)+1)

note_idx = np.arange(12, dtype="uint32")
harm_idx = np.arange(N_HARMONICS)
cross_harm_idx = cross_p_idx(N_HARMONICS, N_HARMONICS)


def kernel_fn(nums, width=0.01):
    "returns rect kernel product of points [f1, a1, f2, a2]"
    return (abs(nums[0]-nums[2])<width)*nums[1]*nums[3]

def v_kernel_fn(f1, f2, a1, a2, widths=0.01):
    "returns rect kernel product of points [f1, a1, f2, a2]"
    return (np.abs(f1-f2)<widths)*a1*a2

def note_product(n1, n2):
    "note-specific cross-product"
    harm_fs = np.vstack([
        note_harmonics[n1,:][cross_harm_idx[0]],
        energies[cross_harm_idx[0]],
        note_harmonics[n2,:][cross_harm_idx[1]],
        energies[cross_harm_idx[1]],
    ])
    return np.apply_along_axis(kernel_fn, 0, harm_fs).sum()

def chord_notes_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")

def make_chord(notes):
    chord_harm_fs = note_harmonics[notes,:].flatten()
    chord_harm_energies = np.tile(base_energies, len(notes))
    return np.vstack([chord_harm_fs, chord_harm_energies])

def chord_product(c1, c2):
    idx = cross_p_idx(c1.shape[1], c2.shape[1])
    harm_fs = np.vstack([
        c1[:,idx[0]],
        c2[:,idx[1]]
    ])
    if harm_fs.shape[1]>0:
        return np.apply_along_axis(kernel_fn, 0, harm_fs).sum()
    else:
        return 0

def chord_dist(c1, c2):
    "construct a chord distance from the chord inner product"
    return sqrt(
        chord_product(c1, c1)
        - 2 * chord_product(c1, c2)
        + chord_product(c2, c2)
    )

def v_chord_product(c1, c2):
    idx = cross_p_idx(c1.shape[1], c2.shape[1])
    if idx.size==0:
        return 0.0
    f1 = c1[0,idx[0]]
    f2 = c2[0,idx[1]]
    a1 = c1[1,idx[0]]
    a2 = c2[1,idx[1]]
    return v_kernel_fn(f1, f2, a1, a2).sum()

def v_chord_dist(c1, c2):
    "construct a chord distance from the chord inner product"
    return sqrt(
        v_chord_product(c1, c1)
        - 2 * v_chord_product(c1, c2)
        + v_chord_product(c2, c2)
    )

def chord_product_from_chord_i(ci1, ci2):
    ci1 = int(ci1)
    ci2 = int(ci2)
    indices = tuple(sorted([ci1, ci2]))
    if not indices in _chord_product_from_chord_i_cache:
        _chord_product_from_chord_i_cache[indices]  = chord_product(
            make_chord(chord_notes_from_ind(ci1)),
            make_chord(chord_notes_from_ind(ci2))
        )
    return _chord_product_from_chord_i_cache[indices] 
_chord_product_from_chord_i_cache = {}

def chord_dist_from_chord_i(ci1, ci2):
    "construct a chord distance from the chord inner product"
    print ci1, ci2
    return sqrt(
        v_chord_product_from_chord_i(ci1, ci1)
        - 2 * v_chord_product_from_chord_i(ci1, ci2)
        + v_chord_product_from_chord_i(ci2, ci2)
    )

def v_chord_product_from_chord_i(ci1, ci2):
    ci1 = int(ci1)
    ci2 = int(ci2)
    indices = tuple(sorted([ci1, ci2]))
    if not indices in _chord_product_from_chord_i_cache:
        _v_chord_product_from_chord_i_cache[indices]  = v_chord_product(
            make_chord(chord_notes_from_ind(ci1)),
            make_chord(chord_notes_from_ind(ci2))
        )
    return _v_chord_product_from_chord_i_cache[indices] 
_v_chord_product_from_chord_i_cache = {}

def v_chord_dist_from_chord_i(ci1, ci2):
    "construct a chord distance from the chord inner product"
    print ci1, ci2
    return sqrt(
        v_chord_product_from_chord_i(ci1, ci1)
        - 2 * v_chord_product_from_chord_i(ci1, ci2)
        + v_chord_product_from_chord_i(ci2, ci2)
    )
