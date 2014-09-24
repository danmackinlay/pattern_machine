# hand rolled ghetto chord similarity measure gives us a similarity matrix
# assumptions: 
# all notes are harmonically truncated saw waves
# all harmonics wrapped to the octave
# can construct a similarity by the inner product based on inner product of the the kernel-approximated vectors, then measuring ratio to mean inner norm; this is more-or-less the covariance of spectral energy
# also could track kernel width per-harmonic; is this principled? "feels" right, but we'll see.
# Could do a straight nearness search off the distance matrix using ball tree
# or cast to a basis of notes using a custom kernel
# need to have this in terms of notes though

import numpy as np
from scipy.spatial.distance import squareform, pdist
from math import sqrt
import tables
import gzip
import cPickle as pickle
from sklearn.manifold import MDS
from sklearn.decomposition import PCA, KernelPCA
import os.path

N_HARMONICS = 16
KERNEL_WIDTH = 0.01 # less than this and they are the same note

def cross_p_idx(n1, n2):
    "poor-mans's nditer, written offline when i couldn't look it up"
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
chord_idx = np.arange(2**12).reshape(2**12,1)

def binrotate(i, steps=1, lgth=12):
    "convenient to pack note strings to ints for performance"
    binrep = bin(i)[2:]
    pad_digits = lgth-len(binrep)
    binrep = "0"*pad_digits + binrep
    binrep = binrep[steps:]+binrep[0:steps]
    return int(binrep, base=2)

def v_kernel_fn(f1, f2, a1, a2, widths=0.01):
    "returns rect kernel product of points [f1, a1, f2, a2]"
    return (np.abs(f1-f2)<widths)*a1*a2

def chord_notes_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_ind_from_notes(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")

def make_chord(notes):
    notes = tuple(sorted(notes))
    if not notes in _make_chord_cache:
        chord_harm_fs = note_harmonics[notes,:].flatten()
        chord_harm_energies = np.tile(base_energies, len(notes))
        _make_chord_cache[notes] = np.vstack([
            chord_harm_fs, chord_harm_energies
        ])
    return _make_chord_cache[notes]
if "_make_chord_cache" not in globals():
    if os.path.exists('_chord_map_cache_make_chords.gz'): 
        with gzip.open('_chord_map_cache_make_chords.gz', 'rb') as f:
            _make_chord_cache = pickle.load(f)
    else:
        _make_chord_cache = {}

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
    
def v_chord_product_from_chord_i(ci1, ci2):
    ci1 = int(ci1)
    ci2 = int(ci2)
    indices = tuple(sorted([ci1, ci2]))
    if not indices in _v_chord_product_from_chord_i_cache:
        prod = v_chord_product(
            make_chord(chord_notes_from_ind(ci1)),
            make_chord(chord_notes_from_ind(ci2))
        )
        #python floats pickle smaller for some reason
        prod = float(prod)
        # for s in xrange(12):
        #     next_indices = tuple(sorted([
        #         binrotate(ci1,s), binrotate(ci2,s)
        #     ]))
        #     print "MISS", next_indices, prod
        #     _v_chord_product_from_chord_i_cache[next_indices] = prod
        _v_chord_product_from_chord_i_cache[indices] = prod
        return prod
    else:
        prod = _v_chord_product_from_chord_i_cache[indices]
        #print "HIT", indices, prod
        return prod
if "_v_chord_product_from_chord_i_cache" not in globals():
    if os.path.exists('_chord_map_cache_products.gz'):
        with gzip.open('_chord_map_cache_products.gz', 'rb') as f:
            _v_chord_product_from_chord_i_cache = dict(pickle.load(f))
    else:
        _make_chord_cache = {}


def v_chord_dist_from_chord_i(ci1, ci2):
    "construct a chord distance from the chord inner product"
    v_chord_dist_from_chord_i.callct = v_chord_dist_from_chord_i.callct + 1
    if (v_chord_dist_from_chord_i.callct % 11==0):
        print ci1, ci2
    return sqrt(
        v_chord_product_from_chord_i(ci1, ci1)
        - 2 * v_chord_product_from_chord_i(ci1, ci2)
        + v_chord_product_from_chord_i(ci2, ci2)
    )
v_chord_dist_from_chord_i.callct = 0

chords_i_dists_square = None
chords_i_dists = None
chords_i_products = None
chords_i_products_square = None
    
if os.path.exists("dists.h5"):
    with tables.open_file("dists.h5", 'w') as handle:
        chords_i_dists = handle.get_node("/", 'v_dists').read()
        chords_i_dists = handle.get_node("/", 'v_sq_dists').read()
        chords_i_dists = handle.get_node("/", 'v_products').read()
        chords_i_dists = handle.get_node("/", 'v_sq_products').read()
else:
    chords_i_dists = pdist(
        chord_idx,
        v_chord_dist_from_chord_i
    )
    chords_i_dists_square =squareform(chords_i_dists)
    chords_i_products = pdist(
        np.arange(2**12).reshape(2**12,1),
        v_chord_product_from_chord_i
    )
    chords_i_products_square = squareform(chords_i_products)

if not os.path.exists("dists.h5"):
    with tables.open_file("dists.h5", 'w') as handle:
        data_atom_type = tables.Float32Atom()
        filt=tables.Filters(complevel=5)
        handle.create_carray("/",'v_dists',
            atom=data_atom_type, shape=chords_i_dists.shape,
            title="dists",
            filters=filt)[:] = chords_i_dists
        handle.create_carray("/",'v_sq_dists',
            atom=data_atom_type, shape=chords_i_dists_square.shape,
            title="sq dists",
            filters=filt)[:] = chords_i_dists_square
        handle.create_carray("/",'v_products',
            atom=data_atom_type, shape=chords_i_products.shape,
            title="product",
            filters=filt)[:] = chords_i_products
        handle.create_carray("/",'v_sq_products',
            atom=data_atom_type, shape=chords_i_products_square.shape,
            title="sq products",
            filters=filt)[:] = chords_i_products_square

if not os.path.exists('_chord_map_cache_products.gz'):
    #this pickle is incredibly huge; dunno why
    with gzip.open('_chord_map_cache_products.gz', 'wb') as f:
        pickle.dump(_v_chord_product_from_chord_i_cache, f, protocol=2)
if not os.path.exists('_chord_map_cache_make_chords.gz'):
    #this one is tiny
    with gzip.open('_chord_map_cache_make_chords.gz', 'wb') as f:
        pickle.dump(_make_chord_cache, f, protocol=2)

kpca = KernelPCA(n_components=None, kernel='precomputed', eigen_solver='auto', tol=0, max_iter=None)
kpca_trans = kpca.fit_transform(chords_i_products_square) #feed the product matric directly in for precomputed case. 

mds = MDS(n_components=3, metric=True, n_init=4, max_iter=300, verbose=1, eps=0.001, n_jobs=3, random_state=None, dissimilarity='precomputed')
mds_trans = mds.fit_transform(chords_i_dists_square)