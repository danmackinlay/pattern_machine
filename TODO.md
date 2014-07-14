* mine metal percussion for peak distribution
  * https://github.com/glyg/peak_detection
  * http://www.nature.com/nmeth/journal/v5/n8/full/nmeth.1233.html
  * http://eprints.nuim.ie/2337/1/JG_SIMPL.pdf
  * (more noise oriented?) https://gist.github.com/sixtenbe/1178136
  * http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2631518/
  * http://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.find_peaks_cwt.html
  * or maybe even filter the spectral peaks using http://wiki.scipy.org/Cookbook/SavitzkyGolay
* Generalise reverb to Gerzon m-dimensional allpass 
  * https://en.wikipedia.org/wiki/Unitary_operator
  * https://ccrma.stanford.edu/~jos/pasp/Gerzon_Nested_MIMO_Allpass.html
* create an allpass that handles crossfades of params gracefully
  * transcription for FAUST’s eﬀect.lib: J.O.Smith, for description and analysis, see
  * https://ccrma.stanford.edu/~jos/Reverb/Reverb_4up.pdf¸
  * https://ccrma.stanford.edu/~jos/pasp/FDN_Reverberators_Faust.html¸
  * http://rev-plugins.sourcearchive.com/lines/0.3.1/¸see
  * http://www.uni-weimar.de/medien/wiki/images/Schlemmer_reverb.pdf
  * http://chiselapp.com/user/jcage/repository/rdk/doc/www/www/revdev.html
* change multichannel naming convention to match ddw - something like __1x2
* control RME mixer from supercollider
* you can constrain a synth genom for evolution by only effecting downstream oscs. apart from that f and a shoudl be effected. The method to use here is "inject".  http://sccode.org/1-4SM
* random param mapping thing
  * Gaussian correlation
  * Student-t correlation
  * map params to physical model
  * Cauchy correlation
* rhythms
  * randomiser pattern
  * quantizer pattern
  * or a clock?
  * hawkes process
* sync oscillator system
  * continuous Kuramoto, possibly on a graph
  * or Strogatz/Perkel/Haken-style pulse-synch, possibly on a graph
  * exotic other
  * call it "phase sync"
  * http://www.scholarpedia.org/article/Synchronization
  * http://www.scholarpedia.org/article/Pulse_coupled_oscillators
  * left-field idea: work using decaying harmonics through feedback - macroscopic karplus-strong.
  * nice brownian calc treatment: http://www.math.uiuc.edu/~rdeville/research/nk.pdf suggests N!=4 and neirest neighbour networks
* find some way of interpreting a call-and-response composition like Stockhausen's Stimmung for laptop thing
* tuvasynth - roaming resonant filters on vocal-like samples (formant filters?)
* grab bag
  * execute scsynth NRT from python (and vice versa?)
  * Faust plugin to define Faust modules for numpy (already exists in octave version)
  * remixer where grains scrub the buffer at different rates but each mutes itself according to its dissonance
  * pure server-side CFDG
  * analyse metal percussion for distribution of frequencies
  * circular sequencer
  * zahedi-style information sensorimotor loop
  * auto sub maximising bassline thing, octavising osciallators until they are all in the right bandwidth
  * "futurising delay" - does JUST LESS than 1 bar
  * angklung attack-opriented granular synth
  * marsenator that marsenates samples
  * notestream app, streaming chords in different patterns to different midi channels
  * polyrhythm as highlighting different cycles within a rhythmn cascade
  * imply a pure server-side pso or particle filter flocking algorithm
  * granular flanger with nice tuning options
  * automatic synth-tracking eye-candy for grammarthing
  * particle filter tracking models
  * (phrase) phrase sampler
  * microproducer effect synths
  * 2d effects crossfade buss, maybe with a well-like dropp it in doppler thing. sountoirs of lfos are revealed over time
  * 3D effect scape through which we drop sound grains that rewrite and recolour themslves.
  * learn the inverse mapping from sound to synth parameters by hearing and comparing resynthesised version with delayed or recorded version, enveloped appropriately.
