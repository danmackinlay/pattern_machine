arpeggiate by numbers
========================

Learning cellular harmony automata

MIDI parsing:
----------------

* http://python.6.x6.nabble.com/midi-file-parser-td1066563.html
* https://groups.google.com/forum/#!msg/alt.sources/eRG2bL3Re-k/FvRLrRl0RiIJ
* http://web.mit.edu/music21/doc/index.html
* http://stackoverflow.com/a/14611850
* realtime output might even be possible thanks to http://portmedia.sourceforge.net/portmidi/doxygen/

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

### neural network

see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

Full blown deep learning feels like overkill, but i feel like i could do some *un*principled feature construction as input to the logistic model which might get me just as far.
we suspect marginal changes in features have a linear effect, fine
but we also suspect that interaction terms are critical;
Naive approach: walk through term-interaction space, discrectized.
Start with one predictor, and add additional predictors randomly (greedily) if the combination
has improved deviance wrt the mean.

I do this at the moment, but my method is flawed, as it does not account for "diameter" - how many notes are candidates to sound.

I could always give up and infer hidden markov states.

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


TODO
------

* truncate fit models to a minimum coeff magnitude (1E-17 is being silly for an event occurring .1% of the time)
* rename "feature" functions as used in python and SC implementation to "basis" functions to reduce confusion with, e.g. bar position
* make the feature mapping a little less ad-hoc "F1,F2,F4" what is this shit?
* fix bar position features - currently totally broken.

  * weight features to de-favour annoying ones such as bar position
  * or use bar features to fit models conditionally; might be cleaner.
  
* fix per-note-rate feature. ill-posed and broken ATM. Even if it didn't glitch out to 0, I didn't code it to translate across songs.
* more generous compound feature search which allows features to appear which are *ONLY* interaction terms, despite both parents not being significant
* hint hdf chunk size http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays
* trim data set to save time http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?
* use formal feature selection to save time? http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool
* Switch to pure python using liblinear http://www.csie.ntu.edu.tw/~cjlin/liblinear/
  
  NB Maybe not. Very slow in liblineaR atm - no nice optimisations for logistic regression or binary factors as in glmnet/R
* save metadata:
  * MAX_AGE
  * matrix dimensions
  * source dataset
* factor mapping
* call into R using rpy2 or even subprocess
* predict inter-event times - would be a natural multiple classification task
* Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve individual obs together while forgetting songs. This requires us to fold on eventId not obsId.

Feature ideas
-----------------

* I have a lot of data here;

  should probably throw over CV and do straight training/prediction split
* fits could know own AND NEIGHBOURS' base rates
* Add a logical feature specifying bar position; possibly fit separate models for each
  * This doesn't seem to add much, only cropping up in very high order features; should I ditch it? If i keep it it should not be nonsensically implemented.

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