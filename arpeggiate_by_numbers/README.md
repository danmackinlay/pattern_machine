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
* can I just offline learn an MDS chord transition thing by some kinda chord similarity metric?
  * maybe; the optimality criterion will be a little weird; I wish to maximis evenness of point distribution, and number of neighbours. Thismight be a different manifold criterion than MDS. perhaps isotonic?
  * this would be nice; sparse kernel (as in KDE) vector product; a littel expensive to evaluate. I wonder if I coudl make it into a kernel (as in kernel trick) product?
  * that would also allow dissonance (negative shoulder) kernels

In fact, this ISN'T a Markov model as it stands; since we only recal the most
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
  * naive model: recentness versus relative pitch, linear in each. This would be sorta easy to implement. Should we also regress on correct value for recentness then?
  * Or regress against something time-bound, perhaps...
    * decaying sinusoidal impulses? but with what period? likely several harmonics of note length.
    * What decay? No idea. Even several superposed decays could be natural. Would have to fit term decay, which would not be linear
    * this might possibly work via some kind of iterative method such as expectation maximisation, or just normal newton-raphson optimisation even; it would be polynomial of order no great than degree of interactions tested, which would be exactly automatically differentiable
    * How would we handle phase? probably by regressing against componenets of an imaginary wave separatedly.
* truncate fit models to a minimum coeff magnitude (1E-17 is a silly weight for
  an event occurring .001% of the time)
* rename "feature" functions as used in python and SC implementation to "bases"
* Change the asymmetry of the cell-based model: regress each row against the previous row;
* or even against eveything other than itself in the row and the previous rows.
* but then how do you simulate from such a model? How do you start the new row?
* You use a model in which you can *optionally* conditionalise on the neighbours. What does this correspond to in the linear case? In the binary?
* but so you run the test for each tone in the new row and conditionalise on the neighbours
* you could get this for cheap by fitting an estimator for the tones based on lower tones in this row and all tones in previous row - if you don't mind always arpeggiating up the octave. And fitting 12 models.
  * more generally *sigh* maybe you could fit a different 12 models; the 12 contingent on how many other notes there are in this row already (there would only be enough data for the first 5, max.) You would fit, e.g. the 2 note model on all 2-note rows, plus all 2-note subsets fo 3 notes rows, to capture the likelihood of stopping after that many notes
  * you could also infer over all possible row histories, which woudl lead to a combinatorial explosion
  * or ordered histories
  * or random histories
  * might stil bea ble to get harmonicity detecion with the regressing-on-lower-notes thing, but always shifting the modulus? No, that would always ignore some information.
* use formal [feature selection](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool)
* more generous compound feature search which allows features to appear which
  are *ONLY* interaction terms, despite both parents not being significant
  
  * Well, the principled way of finding the maximally broad principled way of doing this is precicely the PC algorithm.
  * (To think: should i then make a graph of all interaction terms?)
  * I use the PC-algorithm to find parents of the note sounding thing, then either use that conditional distribution table, or regress against the parent set.
  * this could be sped up (if supported) by enforcing causal arrow directions between timesteps

* does this mean i should use the model as is? implement graphical model outputs in SC?
* [hint hdf chunk size](http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays)
* [trim data the set](http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?)
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

