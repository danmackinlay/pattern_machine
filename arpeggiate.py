from pprint import pprint
import os
import csv
import tables
from util import total_detunedness, span_in_5ths, span_in_5ths_up, span_in_5ths_down
import random
from random import randint, sample
import warnings
import math
from analyse import lik_test, log_lik_ratio, square_feature, triangle_feature
from scipy.sparse import coo_matrix, dok_matrix
from scipy.stats import power_divergence
from sklearn.linear_model import Lasso, LogisticRegression

from parse_midi import *
from config import *

###PROBABILISTIC CONCERNS
# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environment, which note goes on.
# should try and attribute amt of error to each song
# I could go to AIC or BIC instead of cross validation to save CPU cycles

#### IMPLMEMENTING LINEAR MODEL
# See R packages glmnet, liblineaR, rms
# NB liblineaR has python binding
# if we wished to use non penalized regression, could go traditional AIC style: http://data.princeton.edu/R/glms.html
# OR even do hierarchical penalised regression using http://cran.r-project.org/web/packages/glinternet/index.html
# For now
# see http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
# and http://www.jstatsoft.org/v33/i01/paper

# if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.



###TODO:
# hint hdf chunk size http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays
# trim data set to save time http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?
# use feature selection to save time? http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool
# Switch to pure python using liblinear http://www.csie.ntu.edu.tw/~cjlin/liblinear/
# save metadata:
# # MAX_AGE
# # matrix dimensions
# # source dataset
# # factor mapping
# bludgeon R into actually reading the fucking metadata Grrrr R.
# explicitly use R-happy names for CSV, for clarity
# call into R using rpy2, to avoid this horrible manual way of doing things, and also R
# could fit model condition on NUMBER OF HELD NOTES which would be faster to infer and to predict, and more accurate

### FEATURE CONCERNS
#TODO: I have a lot of data here;
# should probably throw over CV and do straight training/prediction split
# todo: fits should know own AND NEIGHBOURS' base rates
# remove rows, and disambiguate what remains. (trimming columns leads to spurious duplicates with 0 notes in)
# Add a logical feature specifying bar position; possibly fit separate models for each

# Bonus datasets I jsut noticed on http://deeplearning.net/datasets/
# Piano-midi.de: classical piano pieces (http://www.piano-midi.de/)
# Nottingham : over 1000 folk tunes (http://abc.sourceforge.net/NMD/)
# MuseData: electronic library of classical music scores (http://musedata.stanford.edu/)
# JSB Chorales: set of four-part harmonized chorales (http://www.jsbchorales.net/index.shtml)

# see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
# http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

# Deep learning feels like overkill, but i feel like i could do some *un*principled feature construction;
# we suspect marginal changes in features have a linear effect, fine
# but we also suspect that interaction terms are critical;
# can we manufacture some hopefully-good features without an exhuastive, expensive, simultaneous optimisation over all of them?
# Naive approach: walk through term-interaction space, discrectized. Start with one predictor, and add additional predictors randomly (greedily) if the combination has improved deviance wrt the mean. it "feels" like features shoudl be positive or negative
# # If i wanted features that did not naturally look discrete i coudl fit minature linear models to each combination?
# # Or make features that correspond to being "near" some value
# # it seems like boolean opeartions on features should also be allowed - intersections and unions and such
# # this could be  naturally accomplished by generating each generation of eatures from the previous and ditching the crappy ones. This feels dangerously close to evolutionary algorithms, or maybe random forests or somesuch. vectorisable tho.
# I could always give up and infer hidden markov states. sigh.

# current model is ugly but works - Not guarnnteed to respect hierarchicality but seems to anyway.
# go to "time-since-last-onset" rather than midi note hold times, which are very noisy anyway. NB - large data sets.
# experiment with longer note smears
# experiment with adaptive note smearing
# I would like to capture spectrally-meaningful relations
# # such as projecting onto harmonic space
# # note that otherwise, I am missing out (really?) under-represented transitions in the data.
# # I could use Dictionary learning http://scikit-learn.org/stable/modules/decomposition.html#dictionary-learning to reduce the number of features from the combinatorial combinations (feels weird; am I guaranteed this will capture *important* features?)
# # I could use PCA - http://scikit-learn.org/stable/modules/decomposition.html#approximate-pca
# # I could use NNMF - http://scikit-learn.org/stable/modules/decomposition.html#non-negative-matrix-factorization-nmf-or-nnmf
# # TruncatedSVD also looks sparse-friendly and is linguistics-based - i.e. polysemy friendly
# Interesting idea might be to use a kernel regression system. Possible kernels (pos def?)
# # Convolution amplitude (effectively Fourier comparison)
# # mutual information of square waves at specified frequency (discrete distribution!)
# # # or Pearson statistic!
# # or mutual information of wavelength count at specified frequency
# # could be windowed. Real human hearing is, after all...
# improved feature ideas:
# # feature vector of approximate prime decomposition of ratios
# # number of held notes (nope, no good)
# # time since last note at a given relative pitch (not clear what to do with this yet)
# # span in 5ths at various time offsets (nope, didn't work)
# # f-divergence between spectral band occupancy folded onto one octave (free "smoothing" param to calibrate, slow, but more intuitive. Not great realtime...)

meta_table_description = {
    'result': tables.IntCol(dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'thisNote': tables.UIntCol(), # midi note number for central pitch
    'obsID': tables.UIntCol(), #  for matching with the other data
    'eventID': tables.UIntCol(), # working out which event cause this
}

barcode_table_description = {
    'obsID': tables.UIntCol(), #  for matching with the other data
    'b5': tables.IntCol(),
    'b4': tables.IntCol(),
    'b3': tables.IntCol(),
    'b2': tables.IntCol(),
    'b1': tables.IntCol(),
}


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
feature_pvals = [lik_test(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]
feature_liks = [log_lik_ratio(feature_sizes[i], feature_successes[i], base_success_rate) for i in xrange(len(feature_sizes))]

# Here begins an unprincipled feature search. Lazily we will assume that success features
# contain all the relevent information

min_size = base_size/10000
p_val_thresh = 0.05 #loose! multiple comparision prob
max_features = 1000
#tol = 1.01

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
# mega_target = meta_result.astype(np.float64)
# mod = LogisticRegression(C=1.0, penalty='l1', tol=1e-6)
# mod.fit(mega_features, mega_target)

# So we go to R: (csr for liblineaR use, csc for R use)
mega_features = sp.sparse.hstack(features).tocsc()

# Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve individual trials together while forgetting songs.

#Todo also: predict inter-event times - would be a natural multiple classification tastk

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
    table_handle.create_carray('/','v_col_names',
        atom=tables.StringAtom(
            max([len(n) for n in feature_names])
        ), shape=(len(feature_names),),
        title="colnames",
        filters=filt)[:] = feature_names
    table_handle.create_carray('/','v_datadims',
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
