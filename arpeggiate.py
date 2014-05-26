from pprint import pprint
import os
import tables
import random
from random import randint, sample
import warnings
import math
from analyse import lik_test, log_lik_ratio, square_feature, triangle_feature
from scipy.sparse import coo_matrix, dok_matrix
from scipy.stats import power_divergence
from sklearn.linear_model import Lasso, LogisticRegression

from parse_midi import get_data_set
from config import *


meta_table_description = {
    'result': tables.IntCol(dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'thisNote': tables.UIntCol(), # midi note number for central pitch
    'obsID': tables.UIntCol(), #  for matching with the other data
    'eventID': tables.UIntCol(), # working out which event cause this
    'b5': tables.IntCol(),
    'b4': tables.IntCol(),
    'b3': tables.IntCol(),
    'b2': tables.IntCol(),
    'b1': tables.IntCol(),
}

##################################

def numpyfy_tuple(obs_meta, obs_vec, mean_pitch_rate):
    n_obs = len(note_meta['obsId'])
    obs_vec['obs_list'] = np.asarray(obs_list, dtype=np.int32)
    obs_vec['p_list'] = np.asarray(p_list, dtype=np.int32)
    obs_vec['recence_list'] = np.asarray(recence_list, dtype=np.float32)
    obs_vec = coo_matrix(
        (
            obs_vec['recence_list'],
            (obs_vec['obs_list'], obs_vec['p_list'] )
        ),
        shape=(n_obs, NEIGHBORHOOD_RADIUS*2+1)).tocsc()
    mean_pitch_rate = np.asarray(mean_pitch_rate, dtype=np.float32)

    barcode_arr = np.zeros((n_obs,4), dtype=np.int32)
    barcode_arr[:,0] = obs_meta['b1']
    del(obs_meta['b1'])
    barcode_arr[:,1] = obs_meta['b2']
    obs_meta['b2']
    barcode_arr[:,2] = obs_meta['b3']
    obs_meta['b3']
    barcode_arr[:,3] = obs_meta['b4']
    obs_meta['b4']
    obs_meta['barcode'] = barcode_arr

    obs_meta['file'] = np.asarray(obs_meta['file'])
    obs_meta['obsId'] = np.asarray(obs_meta['obsId'], dtype = np.int32)
    obs_meta['eventId'] = np.asarray(obs_meta['eventId'], dtype = np.int32)
    obs_meta['thisNote'] = np.asarray(obs_meta['thisNote'], dtype = np.int32)
    obs_meta['result'] = np.asarray(obs_meta['result'], dtype = np.int32)
    obs_meta['time'] = np.asarray(obs_meta['time'], dtype = np.float32)

    return obs_meta, obs_vec, mean_pitch_rate

######################################### former analyse module
obs_meta, obs_vec, mean_pitch_rate = numpyfy_tuple(get_data_set())
n_obs = note_meta['obsId'].size
base_success_rate = note_meta["result"].mean()

n_basic_vars = NEIGHBORHOOD_RADIUS * 2 + 1
max_age = note_meta.attrs.maxAge

base_rate = table_handle.get_node('/', 'v_base_rate').read().astype(np.float32)
rel_base_rate = table_handle.get_node('/', 'v_rel_base_rate').read().astype(np.float32)
col_names = [r['rname'] for r in table_handle.get_node('/', 'col_names').iterrows()]
f0 = csc_matrix(
    (
        square_feature(obs_vec.data, max_age, 0.125),
        obs_vec.indices,
        obs_vec.indptr
    ), shape=(n_obs, n_basic_vars)
)
f0.eliminate_zeros()
f1 = csc_matrix(
    (
        square_feature(obs_vec.data, max_age-0.25, 0.125),
        obs_vec.indices,
        obs_vec.indptr
    ), shape=(n_obs, n_basic_vars)
)
f1.eliminate_zeros()
f2 = csc_matrix(
    (
        square_feature(obs_vec.data, max_age-0.5, 0.125),
        obs_vec.indices,
        obs_vec.indptr
    ), shape=(n_obs, n_basic_vars)
)
f2.eliminate_zeros()
f4 = csc_matrix(
    (
        square_feature(obs_vec.data, max_age-1.0, 0.125),
        obs_vec.indices,
        obs_vec.indptr
    ), shape=(n_obs, n_basic_vars)
)
f4.eliminate_zeros()

#Now, let's manufacture features.
#first make everythign sparse for consistent multiplying. (expensive for the barcode!)
results_sparse = dok_matrix(note_meta["result"].reshape((note_meta["result"].shape,)+(1,))).tocsc()[:,0]
note_barcode_sparse = dok_matrix(note_meta["barcode"]).tocsc()

#now, hold features in arrays for uniform access
feature_names = []
features = []

feature_names += ["F0" + r_name_for_i[i] for i in xrange(f0.shape[1])]
features += [f0[:, i] for i in xrange(f0.shape[1])]
feature_names += ["F1" + r_name_for_i[i] for i in xrange(f1.shape[1])]
features += [f1[:, i] for i in xrange(f1.shape[1])]
feature_names += ["F2" + r_name_for_i[i] for i in xrange(f2.shape[1])]
features += [f2[:, i] for i in xrange(f2.shape[1])]
feature_names += ["F4" + r_name_for_i[i] for i in xrange(f4.shape[1])]
features += [f4[:, i] for i in xrange(f4.shape[1])]

feature_names += ["b" + str(i+1) for i in xrange(note_barcode_sparse.shape[1])]
features += [note_barcode_sparse[:,i] for i in xrange(note_barcode_sparse.shape[1])]

feature_bases = [(i,) for i in xrange(len(features))]
used_bases = set(feature_bases)
feature_sizes = [f.sum() for f in features]
feature_successes = [f.multiply(results_sparse).sum() for f in features]
feature_probs = [float(feature_successes[i])/feature_sizes[i] for i in xrange(len(feature_sizes))]
feature_pvals = [lik_test(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]
feature_liks = [log_lik_ratio(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]

# Here begins an unprincipled feature search. Lazily we will assume that success features
# contain all the relevent information

min_size = n_obs/10000
p_val_thresh = 0.05 #loose! multiple comparision prob
max_features = 1000


while True:
    i, j = 0, 0
    while True:
        #should we be weighting the parent features somehow?
        i, j = sorted(sample(xrange(len(features)), 2))
        prop_basis = tuple(sorted(set(feature_bases[i]+feature_bases[j])))
        if prop_basis not in used_bases: break
    used_bases.add(prop_basis)
    prop_name = ":".join([feature_names[f] for f in prop_basis])
    print "trying", prop_name
    prob_i = feature_probs[i]
    prob_j = feature_probs[j]
    prop_feat = features[i].multiply(features[j])
    prop_size = prop_feat.sum()
    if prop_size<min_size:
        #pretty arbitrary here
        continue
    prop_succ = prop_feat.multiply(results_sparse).sum()
    prop_prob = float(prop_succ)/prop_size
    prop_pval = max(
        lik_test(prop_size, prop_succ, prob_i),
        lik_test(prop_size, prop_succ, prob_j),
    )
    parent_lik = max(
        feature_liks[i],
        feature_liks[j],
    )
    # Base success rate is the wrong criterion here; it should be whether our marginal probs
    # are different than the parents:
    prop_lik = log_lik_ratio(prop_size, prop_succ, base_success_rate)
    
    if prop_pval>p_val_thresh:
        #NB this is a greedy heuristic
        # and it ignores behaviour of negated variable; 2x2 Chi2 would be better
        continue
    #Otherwise, we have a contender. Add it to the pool.
    features.append(prop_feat)
    print "including", prop_name
    feature_names.append(prop_name)
    feature_bases.append(prop_basis)
    feature_sizes.append(prop_size)
    feature_successes.append(prop_succ)
    feature_probs.append(prop_prob)
    feature_liks.append(prop_lik)
    feature_pvals.append(prop_pval)
    if len(features) >= max_features: break

# Here's an arbitrary way of guessing the comparative importance of these:
ranks = sorted([(feature_sizes[i]*feature_liks[i], feature_bases[i], feature_names[i]) for i in xrange(len(features))])
# I could prune the least interesting half and repeat the process?

#recommended feature format.
#TODO: CV http://scikit-learn.org/stable/modules/cross_validation.html#cross-validation
# http://scikit-learn.org/stable/modules/grid_search.html#grid-search
# logistic unsupported for native CV boo
# http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html
# Documentation is scanty, but parallelism thorugh joblib:
# http://packages.python.org/joblib/
# A sample algorithmic trick: warm restarts for cross validation
# TODO: demonstrate the warm restart tricks for cross validation of linear regression with Coordinate Descent.
# NB this might be quicker with SGD
# http://scikit-learn.org/stable/modules/sgd.html#sgd
# mod = SGDClassifier(loss="log", penalty="l1", shuffle=True)
# Incredibly slow:
# mega_features = sp.sparse.hstack(features).tocsr().astype(np.float64)
# mega_target = note_meta["result"].astype(np.float64)
# mod = LogisticRegression(C=1.0, penalty='l1', tol=1e-6)
# mod.fit(mega_features, mega_target)

# So we go to R: (csr for liblineaR use, csc for R use)
mega_features = sp.sparse.hstack(features).tocsc()

# Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve individual trials together while forgetting songs.

#Todo also: predict inter-event times - would be a natural multiple classification tastk

with tables.open_file(BASIC_TABLE_OUT_PATH, 'a') as table_handle:
    #ignore warnings for that bit; I know my column names are annoying.
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        obs_table = table_handle.create_table('/', 'note_meta',
            meta_table_description,
            filters=tables.Filters(complevel=1))
    for r in xrange(n_obs):
        obs_table.row['file'] = obs_meta['file'][r]
        obs_table.row['time'] = obs_meta['time'][r]
        obs_table.row['obsID'] = obs_meta['obsID'][r]
        obs_table.row['eventID'] = obs_meta['eventID'][r]
        obs_table.row['thisNote'] = obs_meta['thisNote'][r]
        obs_table.row['result'] = obs_meta['result'][r]
        obs_table.row['obsID'] = obs_meta['obsID'][r]
        obs_table.row['b4'] = obs_meta['b4'][r]
        obs_table.row['b3'] = obs_meta['b3'][r]
        obs_table.row['b2'] = obs_meta['b2'][r]
        obs_table.row['b1'] = obs_meta['b1'][r]
        obs_table.row.append()

    col_table = table_handle.create_table('/', 'col_names',
        {'i': tables.IntCol(1), 'rname': tables.StringCol(5)})
    for i in sorted(r_name_for_i.keys()):
        col_table.row['i'] = i
        col_table.row['rname'] = r_name_for_i[i]
        col_table.row.append()

    obs_table.attrs.maxAge = MAX_AGE
    obs_table.attrs.neighborhoodRadius = NEIGHBORHOOD_RADIUS

    filt = tables.Filters(complevel=5)

    len_basic = obs_vec.size
    table_handle.create_carray('/','v_obs_indices',
        atom=tables.Int32Atom(), shape=(len_basic,),
        title="obsID",
        filters=filt)[:] = obs_vec.indices
    table_handle.create_carray('/','v_obs_indptr',
        atom=tables.Int32Atom(), shape=(len_basic,),
        title="pitch index",
        filters=filt)[:] = obs_vec.indptr
    table_handle.create_carray('/','v_obs_data',
        atom=tables.Float32Atom(), shape=(len_basic,),
        title="recence",
        filters=filt)[:] = obs_vec.data
    table_handle.create_carray('/','v_base_rate',
        atom=tables.Float32Atom(), shape=(128,),
        title="base rate",
        filters=filt)[:] = mean_pitch_rate
    # Now, because this is easier in Python than in R, we precalc relative pitch neighbourhoods
    # BEWARE 1-BASED INDEXING IN R
    base_rate_store = table_handle.create_carray('/','v_rel_base_rate',
        atom=tables.Float32Atom(), shape=(128,2*NEIGHBORHOOD_RADIUS+1),
        title="rel base rate",
        filters=filt)
    _mean_pitch_rate_plus = [0]*NEIGHBORHOOD_RADIUS + mean_pitch_rate + [0]*NEIGHBORHOOD_RADIUS
    for i in xrange(128):
        base_rate_store[i,:] = _mean_pitch_rate_plus[i:i+(2*NEIGHBORHOOD_RADIUS+1)]
    table_handle.create_carray('/','v_feature_indices',
        atom=tables.Int32Atom(), shape=(mega_features.indices.shape,),
        title="indices",
        filters=filt)[:] = mega_features.indices
    table_handle.create_carray('/','v_feature_indptr',
        atom=tables.Int32Atom(), shape=(mega_features.indptr.shape,),
        title="index ptr",
        filters=filt)[:] = mega_features.indptr
    table_handle.create_carray('/','v_feature_data',
        atom=tables.Int32Atom(), shape=(mega_features.data.shape,),
        title="data",
        filters=filt)[:] = mega_features.data
    table_handle.create_carray('/','v_feature_col_names',
        atom=tables.StringAtom(
            max([len(n) for n in feature_names])
        ), shape=(len(feature_names),),
        title="colnames",
        filters=filt)[:] = feature_names
    table_handle.create_carray('/','v_feature_datadims',
        atom=tables.Int32Atom(), shape=(2,),
        title="data dims",
        filters=filt)[:] = mega_features.shape

# rgr_lasso = Lasso(alpha=0.001)
# rgr_lasso.fit(proj_operator, proj.ravel())
# rec_l1 = rgr_lasso.coef_.reshape(l, l)
# 
# print("Computing regularization path ...")
# start = datetime.now()
# clf = linear_model.LogisticRegression(C=1.0, penalty='l1', tol=1e-6)
# coefs_ = []
# for c in cs:
#     clf.set_params(C=c)
#     clf.fit(X, y)
#     coefs_.append(clf.coef_.ravel().copy())
# print("This took ", datetime.now() - start)
# 
# coefs_ = np.array(coefs_)
# pl.plot(np.log10(cs), coefs_)
# ymin, ymax = pl.ylim()
# pl.xlabel('log(C)')
# pl.ylabel('Coefficients')
# pl.title('Logistic Regression Path')
# pl.axis('tight')
# pl.show(
