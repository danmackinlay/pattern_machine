arpeggiate by numbers
========================

Learning a harmony space

* can I just offline learn an MDS chord transition thing by some kinda chord similarity metric?
  * maybe; the optimality criterion will be a little weird; I wish to maximis evenness of point distribution, and number of neighbours. This might be a different manifold criterion than MDS. perhaps isotonic?
  * this would be nice; sparse kernel (as in KDE) vector product; a littel expensive to evaluate. I wonder if I coudl make it into a kernel (as in kernel trick) product?
  * that would also allow dissonance (negative shoulder) kernels
  * Also, not all distances are equally important; the ones beween two dissontant chords are not significant. can i distort space, or change weightings, to deal with this?
  * If I threw out all chords with more than 6 notes I would also speed up search times. Just sayin'.
* alternatively can i learn  chords by recurrence plot inversion? BEcause what we probably really have is more a c-occurrence recurrence relation (if multivariate)


Notes
======

hand rolled ghetto chord similarity kernel gives us a gram matrix


assumptions: 

* all notes are truncated saw waves with 16 harmonics
* all harmonics wrapped to the octave

Ideas:

also could track (kde) kernel width per-harmonic; is this principled? 
ould do a straight nearness search off the distance matrix using ball tree (4000 is not so many points; brute force also OK)
Or cast to a basis of notes using a custom kernel
need to have this in terms of notes, though

Todo
-----

* weight by actual chord occurence (when do 11 notes play at once? even 6 is pushing it)
* restrict cursor to convex hull of notes, or, e.g. ball?
* exploid rotational symmetry in distance calculations - and analysis
   e.g. hmmm we could position pitch classes rotationally around an axis
   note further that there might be yet more symmetry relationship dependednt
   on the class - but sets of 12 is an obvious one.
* toroidal maps
* simple transition graph might work, if it was made regular in some way
* we could even place chords on a grid in a way that provides minimal dissonance between them; esp since we may repeat chords if necessary. In fact, we could even construct such a path by weaving chords together. Hard to navigate, without some orderings
* a physics-based model might do this reasonably well - springs with constants monotonic in product
* colorize based on number of notes
* Actually integrate kernels together
* use correlation matrix as a markov transition probability weight in some kind of deranged markov model (you'd want some weighting or restriction)
* ditch pickle for optimized tables https://pytables.github.io/usersguide/optimization.html
* For more than ca 6 notes, this is nonsense; we don't care about such "chords"
* interpolate between embeddings live (record current note affinity)
* remove chord 0 (silence), since it only causes trouble.
* rbf spectral embedding with a variable gamma could produce a nice colour scheme, hm?
* octave selection, transposition, # of notes
* switch to JSON for interchange medium
* visualise, somehow, e.g.
  * http://www.ibm.com/developerworks/library/wa-webgl3/
  * http://scenejs.org/
  * http://threejs.org/



Other techniques
----------------------

I was kinda attracted to doing this as a cellular automata, but that was a horrible mess; too much structure outside of my learning.

Can I recover it?

It might be fun to do so by somply looking at outcome rows and eliminating from consideration of them all prior rows which did not help.


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

This might be quicker with [SGD](http://scikit-learn.org/stable/modules/sgd.html#sgd):

    mod = SGDClassifier(loss="log", penalty="l1", shuffle=True)

TODO
------

* handle multiplicity of note events?
  * naive model: recentness versus relative pitch, linear in each. This would be sorta easy to implement. Should we also regress on correct value for recentness then?
  * Or regress against something time-bound, perhaps...
    * decaying sinusoidal impulses? but with what period? likely several harmonics of note length.
    * What decay? No idea. Even several superposed decays could be natural. Would have to fit term decay, which would not be linear
    * this might possibly work via some kind of iterative method such as expectation maximisation, or just normal newton-raphson optimisation even; it would be polynomial of order no great than degree of interactions tested, which would be exactly automatically differentiable
    * How would we handle phase? probably by regressing against componenets of an imaginary wave separatedly.
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

* predict inter-event times - would be a natural multiple classification task

* [A list of alternate datasets](http://notes.livingthing.org/musical_corpora.html).
