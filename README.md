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
* I'd kinda like to do this with a probabilistic graphical model, although the necessity of circular causation makes that messy. This Might work if the previous timestep were the nodes and the *next* were the leaf nodes
* Linguistics has "bag of words"-models that might be interesting to play with?

Method Concerns
----------------------
  
Am I doing this wrong? I could model odds of each note sounding conditional on environment.
Could also model, conditional on environment, which note goes on.
should try and attribute amt of error to each song
I could go to AIC or BIC instead of cross validation to save CPU cycles

### neural network

see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

Deep learning feels like overkill, but i feel like i could do some *un*principled feature construction;
we suspect marginal changes in features have a linear effect, fine
but we also suspect that interaction terms are critical;
Naive approach: walk through term-interaction space, discrectized. Start with one predictor, and add additional predictors randomly (greedily) if the combination has improved deviance wrt the mean. it "feels" like features shoudl be positive or negative

I could always give up and infer hidden markov states. sigh.

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

logistic unsupported for native CV boo

http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LassoCV.html

Documentation is scanty, but parallelism thorugh joblib: http://packages.python.org/joblib/

TODO: demonstrate the warm restart tricks for cross validation of linear regression with Coordinate Descent.

This might be quicker with SGD: http://scikit-learn.org/stable/modules/sgd.html#sgd

    mod = SGDClassifier(loss="log", penalty="l1", shuffle=True)


TODO
------

* weight features to de-favour annoying ones such as bar position
* hint hdf chunk size http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays
* trim data set to save time http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?
* use feature selection to save time? http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool
* Switch to pure python using liblinear http://www.csie.ntu.edu.tw/~cjlin/liblinear/

  NB very slow in liblineaR atm - no nice optimisations for logistic regression or binary factors
* save metadata:
* MAX_AGE
  * matrix dimensions
  * source dataset
  * bludgeon R into actually reading the fucking metadata Grrrr R.
* factor mapping
* feature weighting
* call into R using rpy2 or even subprocess
  * although probably rpy is slower than hdf5, so I should just spawn a script that uses hdf5
* predict inter-event times - would be a natural multiple classification task
* Alternate Fold Idea: simply segment betweeen EVENTS, so as to preserve individual trials together while forgetting songs.

Feature ideas
-----------------

* I have a lot of data here;

  should probably throw over CV and do straight training/prediction split
* fits could know own AND NEIGHBOURS' base rates
* Add a logical feature specifying bar position; possibly fit separate models for each
  * This doesn't seem to add much, only cropping up in very high order features; shoudl I ditch it?

I would like to capture spectrally-meaningful relations

* such as projecting onto harmonic space
* note that otherwise, I am missing out (really?) under-represented transitions in the data.
* I could use Dictionary learning http://scikit-learn.org/stable/modules/decomposition.html#dictionary-learning to reduce the number of features from the combinatorial combinations (feels weird; am I guaranteed this will capture *important* features?)
* I could use PCA - http://scikit-learn.org/stable/modules/decomposition.html#approximate-pca
* I could use NNMF - http://scikit-learn.org/stable/modules/decomposition.html#non-negative-matrix-factorization-nmf-or-nnmf
* TruncatedSVD also looks sparse-friendly and is linguistics-based - i.e. polysemy friendly

Data concerns
--------------

Bonus datasets I jsut noticed on http://deeplearning.net/datasets/

* Piano-midi.de: classical piano pieces (http://www.piano-midi.de/)
* Nottingham : over 1000 folk tunes (http://abc.sourceforge.net/NMD/)
* MuseData: electronic library of classical music scores (http://musedata.stanford.edu/)
* JSB Chorales: set of four-part harmonized chorales (http://www.jsbchorales.net/index.shtml)

the midi parsing is a little funky in that it separates out parts; this means that harmonic relationships are only considered between the current voice, not other voices/instruments
