arpeggiate by numbers
========================

Learning cellular harmony automata

Probabilistic underpinnings:
-----------------------------

* this naive markov model still has lots of hairy bits. Questions:
  * can I get a better "base" point for my notes? e.g. choosing a "key"
  * can I somehow condition on more "control" variables?
  * can I use state transitions to estimate "consonance"?
  * can I generalise somehow? right now this thing will only pass through note states that it has already seen... but if I trained every note with its own transition matrix we could have more notes
* Linguistics has "bag of words"-models that might be interesting to play with?

Possible techniques
----------------------

I could always give up and infer hidden markov states.

### neural network

see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

Full blown deep learning feels like overkill, but ido some *un*principled feature construction as input to the logistic model which might get me just as far.

### PGM

if this DOESN'T work, could go to a discrete PGM model, such as
http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
https://r-forge.r-project.org/R/?group_id=1487
gRaphHD http://www.jstatsoft.org/v37/i01/
http://www.bnlearn.com/
but let's stay simple and start with a linear model;

### specifically that Linear Model

#### In R

See R packages glmnet, liblineaR, rms
NB liblineaR has python binding
if we wished to use non penalized regression, could go traditional AIC style: http://data.princeton.edu/R/glms.html
OR even do hierarchical penalised regression using http://cran.r-project.org/web/packages/glinternet/index.html
For now
see http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
and http://www.jstatsoft.org/v33/i01/paper

#### in Python

TODO: CV http://scikit-learn.org/stable/modules/cross_validation.html#cross-validation
http://scikit-learn.org/stable/modules/grid_search.html#grid-search

logistic unsupported for native CV boo.
http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html

Documentation is scanty, but parallelism thorugh joblib: http://packages.python.org/joblib/

TODO: use the warm restart tricks for cross validation of linear regression with Coordinate Descent.

This might be quicker with SGD: http://scikit-learn.org/stable/modules/sgd.html#sgd

    mod = SGDClassifier(loss="log", penalty="l1", shuffle=True)

### Other trendy alternatives

CMU has a bunch of algorithms in this domain:

* lasso.stars http://cran.r-project.org/web/packages/bigdata/
* Spam http://cran.r-project.org/web/packages/SAM/ http://machinelearning.wustl.edu/mlpapers/paper_files/NIPS2007_415.pdf
* http://sachaepskamp.com/qgraph
* http://cran.r-project.org/web/packages/smart/
* http://cran.r-project.org/web/packages/huge/

TODO
------

* truncate fit models to a minimum coeff magnitude (1E-17 is being silly for an event occurring .1% of the time)
* rename "feature" functions as used in python and SC implementation to "basis" functions
* make the feature mapping a little less ad-hoc "F1,F2,F4" what is this shit?
* fix bar position features ; interacts weirdly with my ad hoc feature manufacture
* it's weird that bar pos and the filter vectors use related by slightly different time quanta, no? Should I change that?
* weight features to de-favour annoying ones
* more generous compound feature search which allows features to appear which are *ONLY* interaction terms, despite both parents not being significant
* hint hdf chunk size http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays
* trim data set to save time http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?
* use formal feature selection to save time? http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool
* Switch to pure python using liblinear http://www.csie.ntu.edu.tw/~cjlin/liblinear/
  
  NB Maybe not. Very slow in liblineaR atm - no nice optimisations for logistic regression or binary factors as in glmnet/R
* fix per-note-rate feature. ill-posed and broken ATM. Even if it didn't glitch out to 0, I didn't code it to translate across songs.
* save metadata:
  * MAX_AGE
  * matrix dimensions
  * source dataset
  * basis parameters
* factor mapping
* call into R using rpy2 or even subprocess
* predict inter-event times - would be a natural multiple classification task
* Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve individual obs together while forgetting songs. This requires us to fold on eventId not obsId.

Feature ideas
-----------------

* I have a lot of data here;

  should probably throw over CV and do straight training/prediction split
* fits could know own AND NEIGHBOURS' base rates

Would I like to capture spectrally-meaningful relations?

* such as projecting onto harmonic space
* I could use NNMF - http://scikit-learn.org/stable/modules/decomposition.html#non-negative-matrix-factorization-nmf-or-nnmf
* TruncatedSVD also looks sparse-friendly and is linguistics-based - i.e. polysemy friendly

Data concerns
--------------

Bonus datasets I just noticed on http://deeplearning.net/datasets/

* Piano-midi.de: classical piano pieces (http://www.piano-midi.de/)
* Nottingham : over 1000 folk tunes (http://abc.sourceforge.net/NMD/)
* MuseData: electronic library of classical music scores (http://musedata.stanford.edu/)
* JSB Chorales: set of four-part harmonized chorales (http://www.jsbchorales.net/index.shtml)

How does midi parsing handle percussion ATM?