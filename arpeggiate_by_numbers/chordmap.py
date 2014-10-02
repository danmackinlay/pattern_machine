# hand rolled ghetto chord similarity measure gives us a similarity matrix
# assumptions: 
# all notes are harmonically truncated saw waves
# all harmonics wrapped to the octave

# can construct a similarity by the inner product based on inner product of the the kernel-approximated vectors, then measuring ratio to mean inner norm; this is more-or-less the covariance of spectral energy
# also could track kernel width per-harmonic; is this principled? "feels" right, but we'll see.
# Could do a straight nearness search off the distance matrix using ball tree (4000 is not so many points; brute force also OK)
# or cast to a basis of notes using a custom kernel
# need to have this in terms of notes, though
# TODO: weight by actual chord occurence (when do 11 notes play at once? even 6 is pushing it)
# TODO: toroidal maps
# TODO: simple transition graph might work, if it was made regular in some way
# TODO: we could even place chords on a grid in a way that provides minimal dissonance between them; esp since we may repeat chords if necessary. In fact, we could even construct such a path by weaving chords together. Hard to navigate, though.
# TODO: segment on number of notes, either before or after MDS
# TODO: segment on total spectral energy; or at least weight transitions on relative energy. (how often do we then increase energy?)
# TODO: colorize base on number of notes
# TODO: ditch python dict serialization in favour of indexed pytables
# TODO: Actually integrate kernels together
# TODO: ditch pickle for optimized tables https://pytables.github.io/usersguide/optimization.html
# TODO: really need to be preserving the seed for this stuff
# TODO: We could use this by constructing 8 2d navigation systems, and for each point, the 7 nearest neighbours in adjacent leaves
# TODO: Or can i just pull out one of these leaves and inspect for what it is?
# TODO: MIDI version
# TODO: straight number-of-notes colour map
# TODO: For more than ca 6 notes, this is nonsense; we don't care about such "chords"
# TODO: switch between embeddings live (record current note affinity)
# TODO: I can't do Locally Linear Embedding because I throw out the original coords (it is not a kernel method). But can I do Spectral Embedding? yep.
# TODO: remove chord 0 (silence), since it only causes trouble.
# TODO: rbf spectral embedding with a variable gamma could produce a nice colour scheme, hm?
# TODO: How about I extract a tendency for more notes from the fit by inferring a "number of notes" field from the density? this would work pretty good on the spectral embedding by rbf.

import numpy as np
from scipy.spatial.distance import squareform, pdist
from math import sqrt
import tables
import gzip
import cPickle as pickle
from sklearn.manifold import MDS, SpectralEmbedding
from sklearn.decomposition import PCA, KernelPCA
import os.path
from sklearn.cluster import SpectralClustering
from chordmap_base import *
import chordmap_vis
from sklearn.covariance import EllipticEnvelope

N_HARMONICS = 16
KERNEL_WIDTH = 0.001 # less than this and they are the same note

chords_i_products_square = None
chords_i_dists_square = None

energies = 1.0/(np.arange(N_HARMONICS)+1)
base_energies = 1.0/(np.arange(N_HARMONICS)+1)
base_harm_fs = np.arange(N_HARMONICS)+1
base_fundamentals = 2.0**(np.arange(12)/12.0)
# wrap harmonics, non-log version
# note_harmonics = (((np.outer(base_fundamentals, base_harm_fs)-1.0)%1.0)+1)
# Alternatively (Thanks James Nichols for noticing)
note_harmonics = 2.0 ** (np.log2(np.outer(base_fundamentals, base_harm_fs))%1.0)

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
    """
    returns rect kernel product of points [f1, a1, f2, a2]
    NB this is not actually a cyclic kernel on [1,2], though the difference is small
    """
    return (np.abs(f1-f2)<widths)*a1*a2

def chord_notes_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_ind_from_notes(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_mask_from_ind(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")
def chord_mask_from_notes(i):
    return np.asarray(np.nonzero(bit_unpack(i))[0], dtype="uint")

#TODO: this might as well be a hdf5 table too, for consistency
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

def v_chord_product_from_chord_i_raw(ci1, ci2):
    """uncached version, for filling the cache with."""
    return v_chord_product(
        make_chord(chord_notes_from_ind(ci1)),
        make_chord(chord_notes_from_ind(ci2))
    )

def v_chord_product_from_chord_i(ci1, ci2):
    """cached version"""
    return chords_i_products_square[ci1, ci2]

def v_chord_dist2_from_chord_i(ci1, ci2):
    """construct a chord distance^2 from the chord inner product
    TODO: there is surely an optimised routine to do this in the MDS module
    would be worth using it, since this step is slow and boring
    """
    #this is just to calculate how often to print progress messages
    v_chord_dist2_from_chord_i.callct = v_chord_dist2_from_chord_i.callct + 1
    if (v_chord_dist2_from_chord_i.callct % 11==0):
        print ci1, ci2
    return (
        v_chord_product_from_chord_i(ci1, ci1)
        - 2 * v_chord_product_from_chord_i(ci1, ci2)
        + v_chord_product_from_chord_i(ci2, ci2)
    )
v_chord_dist2_from_chord_i.callct = 0

if os.path.exists("dists.h5"):
    with tables.open_file("dists.h5", 'r') as handle:
        chords_i_products_square = handle.get_node("/", 'v_sq_products').read()
        chords_i_dists_square = handle.get_node("/", 'v_sq_dists').read()
else:
    chords_i_products_square = squareform(pdist(
        np.arange(2**12).reshape(2**12,1),
        v_chord_product_from_chord_i_raw
    ))
    #but wait! pdist optimised by assuming self-distance is zero
    #but this isn't a distance function! Quick!
    chords_i_products_square[
        np.diag_indices_from(chords_i_products_square)
    ] = [
        v_chord_product_from_chord_i_raw(i,i) for i in xrange(2**12)
    ]

    chords_i_dists_square = squareform(np.sqrt(pdist(
        chord_idx,
        v_chord_dist2_from_chord_i
    )))

if not os.path.exists("dists.h5"):
    with tables.open_file("dists.h5", 'w') as handle:
        data_atom_type = tables.Float32Atom()
        filt=tables.Filters(complevel=5, complib='blosc')
        handle.create_carray("/",'v_sq_products',
            atom=data_atom_type, shape=chords_i_products_square.shape,
            title="sq products",
            filters=filt)[:] = chords_i_products_square
        handle.create_carray("/",'v_sq_dists',
            atom=data_atom_type, shape=chords_i_dists_square.shape,
            title="sq dists",
            filters=filt)[:] = chords_i_dists_square

if not os.path.exists('_chord_map_cache_make_chords.gz'):
    #this one is tiny (probably because repeated floats more compressible)
    with gzip.open('_chord_map_cache_make_chords.gz', 'wb') as f:
        pickle.dump(_make_chord_cache, f, protocol=2)

def get_pca(sq_dists, n_dims=None):
    transformer = KernelPCA(n_components=n_dims, kernel='precomputed', eigen_solver='auto', tol=0, max_iter=None)
    transformed = transformer.fit_transform(sq_dists) #feed the product matric directly in for precomputed case
    return transformed

def get_mds(sq_dists, n_dims=3, metric=True, rotate=True):
    transformer = MDS(n_components=n_dims, metric=metric, n_init=4, max_iter=300, verbose=1, eps=0.001, n_jobs=3, random_state=None, dissimilarity='precomputed')
    transformed = transformer.fit_transform(sq_dists)
    if rotate:
        # Rotate the data to a hopefully consistent orientation
        clf = PCA(n_components=n_dims)
        transformed = clf.fit_transform(transformed)
    return transformed

# 
# def get_lle(sq_dists, n_dims=3, n_neighbors=6):
#     transformer = LocallyLinearEmbedding(n_components=n_dims, metric=metric, n_init=4, max_iter=300, verbose=1, eps=0.001, n_jobs=3, random_state=None, dissimilarity='precomputed')
#     transformed = transformer.fit_transform(sq_dists)
#     if rotate:
#         # Rotate the data to a hopefully consistent orientation
#         clf = PCA(n_components=n_dims)
#         transformed = clf.fit_transform(transformed)
#     return transformed

def get_spectral_embedding_prod(sq_products, n_dims=3):
    #The product matrix is already an affinity; 
    # but it has the undesirable quality of making high energy chords more similar than low energy chords
    # we normalise accordingly
    # Alternatively: RBF. See next fn
    inv_root_energy = 1.0/np.maximum(np.sqrt(np.diagonal(chords_i_products_square)),1)
    affinity = sq_products * np.outer(inv_root_energy,inv_root_energy)
    transformer = SpectralEmbedding(n_components=n_dims, affinity='precomputed')
    transformed = transformer.fit_transform(affinity)
    return transformed


def get_spectral_embedding_dist(sq_dists, n_dims=3, gamma=0.0625):
    # see previous fn
    # this needs to be 64 bit for stability
    sq_dists = sq_dists.astype('float64')
    affinity = np.exp(-gamma * sq_dists * sq_dists)
    transformer = SpectralEmbedding(n_components=n_dims, affinity='precomputed')
    transformed = transformer.fit_transform(affinity)
    # natural scale is dicey on this one. rescale to uni-ish variance
    var = np.var(transformed, 0)
    mean = np.mean(transformed, 0)
    return ((transformed-mean)/np.sqrt(var)).astype('float32')

lin_mds_3 = get_mds(chords_i_dists_square, n_dims=3, rotate=False)
dump_projection("lin_mds_3.h5", lin_mds_3)
clusters = SpectralClustering(n_clusters=12, random_state=None, n_init=16, gamma=16.0, affinity='rbf', n_neighbors=10, assign_labels='kmeans').fit_predict(lin_mds_3)
centers = np.array([lin_mds_3[clusters==i].mean(0) for i in xrange(8)])
most_central = (centers**2).sum(1).argmin()
fave_cluster = lin_mds_3[clusters==most_central]
envelope = EllipticEnvelope(contamination=0.02)
envelope.fit(fave_cluster)
fave_cluster_best_points = fave_cluster[(envelope.predict(fave_cluster)==1).nonzero()[0]]
fave_cluster_ids = (clusters==most_central).nonzero()[0]
anal3 = PCA(n_components=3)
anal3.fit(fave_cluster_best_points)
lin_mds_3_rot = anal3.transform(lin_mds_3)
chordmap_vis.plot_3d(lin_mds_3_rot, clusters)
# can now PCA each group down to 2 elems
anal2 = PCA(n_components=2)
anal2.fit(fave_cluster_best_points)
leaf_1=anal2.transform(fave_cluster) # or this could be an MDS again, from original distances (be careful orchestrating lookups of lookups)


nonlin_mds_3 = get_mds(chords_i_dists_square, n_dims=3, metric=False, rotate=False)
dump_projection("nonlin_mds_3.h5", nonlin_mds_3) #chunky cube
write_matrix(nonlin_mds_3, filename="nonlin_mds_3.scd")

spectral_embed_prod_2 = get_spectral_embedding_prod(chords_i_products_square, n_dims=2)
dump_projection("spectral_embed_prod_2.h5", spectral_embed_prod_2)
chordmap_vis.plot_2d(spectral_embed_prod_2) #radial rainbow ball
write_matrix(spectral_embed_prod_2, filename="spectral_embed_prod_2.scd")

spectral_embed_dist_2 = get_spectral_embedding_dist(chords_i_dists_square, n_dims=2)
dump_projection("spectral_embed_dist_2.h5", spectral_embed_dist_2)
chordmap_vis.plot_2d(spectral_embed_dist_2) #flat saturn. flaturn.
write_matrix(spectral_embed_dist_2, filename="spectral_embed_dist_2.scd")

spectral_embed_prod_3 = get_spectral_embedding_prod(chords_i_products_square, n_dims=3)
dump_projection("spectral_embed_prod_3.h5", spectral_embed_prod_3)
chordmap_vis.plot_3d(spectral_embed_prod_3) #radial rainbow ball
write_matrix(spectral_embed_prod_3, filename="spectral_embed_prod_3.scd")

spectral_embed_dist_3 = get_spectral_embedding_dist(chords_i_dists_square, n_dims=3)
dump_projection("spectral_embed_dist_3.h5", spectral_embed_dist_3)
chordmap_vis.plot_3d(spectral_embed_dist_3) #weird striated honeycomb
write_matrix(spectral_embed_dist_3, filename="spectral_embed_dist_3.scd")

spectral_embed_prod_4 = get_spectral_embedding_prod(chords_i_products_square, n_dims=4)
dump_projection("spectral_embed_prod_4.h5", spectral_embed_prod_4)
chordmap_vis.plot_3d(spectral_embed_prod_4) #radial rainbow ball
write_matrix(spectral_embed_prod_4, filename="spectral_embed_prod_4.scd")

spectral_embed_dist_4 = get_spectral_embedding_dist(chords_i_dists_square, n_dims=4)
dump_projection("spectral_embed_dist_4.h5", spectral_embed_dist_4)
chordmap_vis.plot_3d(spectral_embed_dist_4) #weird striated honeycomb
write_matrix(spectral_embed_dist_4, filename="spectral_embed_dist_4.scd")
