arpeggiate by numbers
========================

Learning cellular harmony automata

Probabilistic underpinnings:
-----------------------------

This naive markov model still has lots of hairy bits. Questions:
* can I get a better "base" point for my notes? e.g. choosing a "key"?
* or just a most common note?
* can I somehow condition on more "control" variables?
* can I use state transitions to estimate "consonance"?

In fact, this ISN'T a MArkov model as it stands; since we only recal the most
recent occurrence of note, threre is an implicit interaction between notes of
different ages. That is Bad.  

Possible techniques
----------------------

### Hidden Markov models

It's been done though, and is boring.

### neural network

see also the [deep learning](http://notes.livingthing.org/deep_learning.html) approach.

Full blown deep learning feels like overkill, but i do some *un*principled
feature construction as input to the logistic model which might get far enough.

### PGM

Could go to a discrete PGM model, such as

* [catnet](http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf)
* [gRaphHD](http://www.jstatsoft.org/v37/i01/)
* [bnlearn](http://www.bnlearn.com/)
* [R overview](https://r-forge.r-project.org/R/?group_id=1487)

but let's stay simple and start with a generalized linear model of some
description.

### specifically binomial regression

Could do various things here;

* Generalized additive models.
* nonparametric propensity scores
* but what I am actually doing is logistic regression.

#### In R

Currently using glmnet to do this. See also liblineaR and even
[glinternet](http://cran.r-project.org/web/packages/glinternet/index.html) for
*hierarchical* penalised regression.
 
#### in Python

Have to [DIY Cross validation](http://scikit-learn.org/stable/modules/cross_validation.html#cross-validation) and [grid search](http://scikit-learn.org/stable/modules/grid_search.html#grid-search)

Logistic is [unsupported for native CV](http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html) boo.

Documentation is scanty, but parallelism through [joblib](http://packages.python.org/joblib/)

TODO: use the warm restart tricks for cross validation of linear regression with Coordinate Descent.

This might be quicker with [SGD](http://scikit-learn.org/stable/modules/sgd.html#sgd):

    mod = SGDClassifier(loss="log", penalty="l1", shuffle=True)

TODO
------

* This model is terrible. It *looks* like it's fitting from the CV curve, but
  the reported deviance explained (0.165) is no better than a randomly permuted
  model with 0 terms. What could I do better?
* wrap notes to octave
* handle multiplicity of note events?
  * Full cellular automata-style, not just recentness of last event (parameter explosion!)
  * regress each-versus-all for every note-co-occurence
  * Or regress against an exponential decay curve
    * have to fit filter time, which will have nonlinear interactions with the other terms
    * plus why would we then expect the response to the exponentially decayed event information to be linear?
    * decaying sinusoidal impulses would seem more natural. but with what period? likely several harmonics of note length. What decay? No idea. Even several superposed decays could be natural.
    * also, what phase would we add to the modeled impulse? harmonic in bar length? (exp(i\theta))? 0 phase added each time? Anyway, this gives us a very large optimisation problem. But possibly we could handle it in the spectral domain. Smoothing problem (per harmonic or overall) + say, 5 harmonics above 0 for each neighbourhood member
* implement graphical model outputs in SC
* truncate fit models to a minimum coeff magnitude (1E-17 is a silly weight for
  an event occurring .001% of the time)
* rename "feature" functions as used in python and SC implementation to "basis"
  functions
* make the feature mapping a little less ad-hoc "F1,F2,F4" what is this shit?
* it's weird that bar pos and the filter vectors are related by slightly
  different time quanta, no? Should I change that? Quantise the entire thing to
  a cellular grid?
* more generous compound feature search which allows features to appear which
  are *ONLY* interaction terms, despite both parents not being significant
* [hint hdf chunk size](http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays)
* [trim data the set](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?)
* use formal [feature selection](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool)
* Switch to pure python using [liblinear](http://www.csie.ntu.edu.tw/~cjlin/liblinear/)
  
  NB Maybe not. Very slow in liblineaR atm - no nice optimisations for logistic regression or binary factors as in glmnet/R
* fix per-note-rate feature. Ill-posed and broken ATM. Even if it didn't glitch
  out to 0, I didn't code it to translate across songs.
* save metadata:
  * MAX_AGE
  * matrix dimensions
  * source dataset
  * basis parameters
* factor mapping
* call into R using subprocess
* predict inter-event times - would be a natural multiple classification task
* Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve
  individual obs together while forgetting songs. This requires us to fold on
  eventId not obsId.

Feature ideas
-----------------

* I have a lot of data here; could probably throw over CV and do straight
  training/prediction split
* fits could know own AND NEIGHBOURS' base rates

Would I like to capture spectrally-meaningful relations?

* such as projecting onto harmonic space - see ps_correl.
* I could use [NNMF](http://scikit-learn.org/stable/modules/decomposition.html#non-negative-matrix-factorization-nmf-or-nnmf)
* TruncatedSVD also looks sparse-friendly and is linguistics-based - i.e. polysemy friendly

Data concerns
--------------

[A list of alternate datasets](http://notes.livingthing.org/musical_corpora.html).

Performance
-----------

Fit within python is incredibly slow, didn't terminate afer 36 hours (!)

    mega_features = sp.sparse.hstack(features).tocsr().astype(np.float64) #TRULY csr?
    mega_target = obs_meta["result"].astype(np.float64)
    mod = LogisticRegression(C=1.0, penalty='l1', tol=1e-6)
    mod.fit(mega_features, mega_target)

see
* http://scikit-learn.org/stable/auto_examples/linear_model/plot_logistic_l1_l2_sparsity.html
* http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html
* http://scikit-learn.org/stable/auto_examples/linear_model/plot_sparse_recovery.html
* http://scikit-learn.org/stable/modules/feature_selection.html#compressive-sensing
* http://leon.bottou.org/projects/sgd

