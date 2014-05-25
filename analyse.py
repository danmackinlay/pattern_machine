from config import *
import numpy as np
import scipy as sp
from scipy.sparse import coo_matrix, dok_matrix
from scipy.stats import power_divergence
from random import randint, sample
from sklearn.linear_model import Lasso, LogisticRegression

import tables

def lik_test(N,Y,p0):
    "likelihood ratio/ G-test. This will suffer from the multiple comparison issue, "
    "but is only an aid to guesstimation anyway."
    Y0 = int(round(p0*N))
    return power_divergence(f_obs=[N-Y,Y], f_exp=[N-Y0,Y0], lambda_="log-likelihood")[1]

def log_lik_ratio(N,Y,p0):
    Y0 = int(round(p0*N))
    return power_divergence(f_obs=[N-Y,Y], f_exp=[N-Y0,Y0], lambda_="log-likelihood")[0]

def square_feature(A, center=2.0, radius=0.125):
    return ((A-center)<radius).astype(np.int32)

def triangle_feature(A, center=2.0, radius=0.125):
    return (1.0-np.abs(A-center)/radius)*((A-center)<radius)

table_handle = tables.open_file(BASIC_TABLE_OUT_PATH, 'r')
note_meta = table_handle.get_node('/', 'note_meta')
n_obs = note_meta.nrows

meta_obsid = note_meta.read(field="obsID").astype(np.int32)
meta_result = note_meta.read(field="result").astype(np.int32)
meta_this_note = note_meta.read(field="thisNote").astype(np.int32)
meta_note_time = note_meta.read(field="time").astype(np.float32)

base_size = len(meta_obsid)
base_success_rate = meta_result.mean()

note_barcode = table_handle.get_node('/', 'note_barcode')
note_barcode_arr = np.zeros((n_obs,4), dtype=np.int32)
note_barcode_arr[:,0] = note_barcode.read(field="b1")
note_barcode_arr[:,1] = note_barcode.read(field="b2")
note_barcode_arr[:,2] = note_barcode.read(field="b3")
note_barcode_arr[:,3] = note_barcode.read(field="b4")

n_basic_vars = note_meta.attrs.neighborhoodRadius * 2 + 1
max_age = note_meta.attrs.maxAge

base_rate = table_handle.get_node('/', 'v_base_rate').read().astype(np.float32)
rel_base_rate = table_handle.get_node('/', 'v_rel_base_rate').read().astype(np.float32)
col_names = [r['rname'] for r in table_handle.get_node('/', 'col_names').iterrows()]

obs_id = table_handle.get_node('/', 'v_obsid').read().astype(np.int32)
basic_var_id = table_handle.get_node('/', 'v_p').read().astype(np.int32)
recence = table_handle.get_node('/', 'v_recence').read().astype(np.float32)

f0 = coo_matrix(
    (
        square_feature(recence, max_age, 0.125),
        (obs_id,basic_var_id))
    ,
    shape=(n_obs, n_basic_vars))
f0 = f0.tocsc()
f0.eliminate_zeros()
f1 = coo_matrix(
    (
        square_feature(recence, max_age-0.25, 0.125),
        (obs_id,basic_var_id))
    ,
    shape=(n_obs, n_basic_vars))
f1 = f1.tocsc()
f1.eliminate_zeros()
f2 = coo_matrix(
    (
        square_feature(recence, max_age-0.5, 0.125),
        (obs_id,basic_var_id))
    ,
    shape=(n_obs, n_basic_vars))
f2 = f2.tocsc()
f2.eliminate_zeros()
f4 = coo_matrix(
    (
        square_feature(recence, max_age-1.0, 0.125),
        (obs_id,basic_var_id))
    ,
    shape=(n_obs, n_basic_vars))
f4 = f4.tocsc()
f4.eliminate_zeros()

#Now, let's manufacture features.
#first make everythign sparse for consistent multiplying. (expensive for the barcode!)
results_sparse = dok_matrix(meta_result.reshape(meta_result.shape+(1,))).tocsc()[:,0]
note_barcode_sparse = dok_matrix(note_barcode_arr).tocsc()

#now, hold features in arrays for consistency
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
#feature_pvals = [lik_test(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]
feature_liks = [log_lik_ratio(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]

# Here begins an unprinciple feature search. Lazily we will assume that success features
# contain all the relevent information

min_size = base_size/10000
p_val_thresh = 10e-2
max_features = 1000
tol = 1.1

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
    # pval_i = feature_pvals[i]
    # pval_j = feature_pvals[j]
    prop_feat = features[i].multiply(features[j])
    prop_size = prop_feat.sum()
    if prop_size<min_size:
        #pretty arbitrary here
        continue
    prop_succ = prop_feat.multiply(results_sparse).sum()
    prop_prob = float(prop_succ)/prop_size
    # prop_pval = max(
    #     lik_test(prop_size, prop_succ, prob_i),
    #     lik_test(prop_size, prop_succ, prob_j),
    # )
    parent_lik = max(
        log_lik_ratio(prop_size, prop_succ, prob_i),
        log_lik_ratio(prop_size, prop_succ, prob_j),
    )
    prop_lik = log_lik_ratio(prop_size, prop_succ, base_success_rate)
    if prop_lik<=parent_lik*tol:
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
    if len(features) >= max_features: break

# Here's an arbitrary way of guessing the comparative importance of these:
ranks = sorted([(feature_sizes[i]*feature_liks[i], feature_bases[i], feature_names[i]) for i in xrange(len(features))])
# I could prune the least interesting half and repeat the process?
# Also note a suspicious number have the same "rank" - something is spurious with my reasoning
# patience; let's fit a model first.

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
# mod = = SGDClassifier(loss="log", penalty="l1", shuffle=True)
# Incredibly slow:
# mega_features = sp.sparse.hstack(features).tocsr().astype(np.float64)
# mega_target = meta_result.astype(np.float64)
# mod = LogisticRegression(C=1.0, penalty='l1', tol=1e-6)
# mod.fit(mega_features, mega_target)

# So we go to R:
mega_features = sp.sparse.hstack(features).tocsr()

with tables.open_file(FEATURIZED_TABLE_OUT_PATH, 'w') as table_handle:
    filt = tables.Filters(complevel=5)

    table_handle.create_carray('/','v_indices',
        atom=tables.Int32Atom(), shape=(mega_features.indices.shape,),
        title="indices",
        filters=filt)[:] = mega_features.indices
    table_handle.create_carray('/','v_indptr',
        atom=tables.Int32Atom(), shape=(mega_features.indptr.shape,),
        title="index ptr",
        filters=filt)[:] = mega_features.indptr
    table_handle.create_carray('/','v_data',
        atom=tables.Int32Atom(), shape=(mega_features.data.shape,),
        title="data",
        filters=filt)[:] = mega_features.data
    table_handle.create_carray('/','v_colnames',
        atom=tables.StringAtom(
            max([len(n) for n in feature_names])
        ), shape=(len(feature_names),),
        title="data",
        filters=filt)[:] = feature_names

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