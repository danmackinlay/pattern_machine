* interface
  * https://github.com/triss/duplex-nexus-osc
  * Lemur
  * circular sequencer
* proper nice machine listening granulation
* general Python OSC serving framework, with talkback to server and client, and multiple different paths.
* mine metal percussion for peak distribution
  * overview of assumption-free methods: http://www.ncbi.nlm.nih.gov/pmc/articles/PMC2631518/
  * but see also Sethares' "A Bell, A Rock, A Crystal" and the analysis of the spectral structure of manufactured gongs and bells
  * "MTT" method
    * https://github.com/glyg/peak_detection
    * http://www.nature.com/nmeth/journal/v5/n8/full/nmeth.1233.html
  * "sinusoidal modelling"
    * http://eprints.nuim.ie/2337/1/JG_SIMPL.pdf
    * http://simplsound.sourceforge.net/
  * wavelets
    * http://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.find_peaks_cwt.html
    * http://bioinformatics.oxfordjournals.org/content/22/17/2059.long
    * http://basic.northwestern.edu/publications/peakdetection/
  * or maybe even filter the spectral peaks using http://wiki.scipy.org/Cookbook/SavitzkyGolay
  * (more noise oriented?) https://gist.github.com/sixtenbe/1178136
* Generalise reverb to Gerzon m-dimensional MIMO allpass 
  * https://en.wikipedia.org/wiki/Unitary_operator
  * https://ccrma.stanford.edu/~jos/pasp/Gerzon_Nested_MIMO_Allpass.html
* Less suspicious nested allpass than DoubleNestedAllpass
  * transcription for FAUST’s eﬀect.lib: J.O.Smith, for description and analysis, see
  * https://ccrma.stanford.edu/~jos/Reverb/Reverb_4up.pdf¸
  * https://ccrma.stanford.edu/~jos/pasp/FDN_Reverberators_Faust.html¸
  * http://rev-plugins.sourcearchive.com/lines/0.3.1/¸see
  * http://www.uni-weimar.de/medien/wiki/images/Schlemmer_reverb.pdf
  * http://chiselapp.com/user/jcage/repository/rdk/doc/www/www/revdev.html
* film soundtrack thing
  * sudden hits
  * chord selection
  * pads
  * vocal tracking
  * phys-modelling-lite - give initial values for params trajectories and attractors; move the attractors using controls
    * stable attactors, with friction
    * hamiltonians, orbits?
* control RME mixer from supercollider
* accumulate energy in varous spectral bins and trigger things based on their levels
* notestream app, streaming chords in different patterns to different midi channels (to ableton?)
* you can constrain a synth genome for evolution by only effecting downstream oscs. both f and a should be effected. 
* random param mapping thing
  * Student-t correlation
  * map params to physical model
  * sparse correlation
  * physical models as input
  * random sparse physical models as input
  * annealing/Gibbs distribution style process
  * Der/Zahedi/Bertschinger/Ay-style information sensorimotor loop
* rhythms
  * recurrent neural networks like http://arxiv.org/abs/1308.0850
  * hawkes process (with repression?)
* sync oscillator system
  * continuous Kuramoto, possibly on a graph
  * or Strogatz/Perkel/Haken-style pulse-sync, possibly on a graph
  * exotic other
  * call it "phase sync"
  * http://www.scholarpedia.org/article/Synchronization
  * http://www.scholarpedia.org/article/Pulse_coupled_oscillators
  * nice brownian calc treatment: http://www.math.uiuc.edu/~rdeville/research/nk.pdf suggests N!=4 and neirest neighbour networks
  * left-field idea: work using decaying harmonics through feedback - macroscopic karplus-strong.
  * any of these would be interesting with driving noise and arbitrary topologies. See also MIMO allpass.
* find some way of interpreting a call-and-response composition like Stockhausen's Stimmung, but for laptops
* tuvasynth - roaming resonant filters on vocal-like samples (formant filters?)
* grab bag
  * particle filters for synth param matching
  * execute scsynth NRT from python (and vice versa?)
  * Faust plugin to define Faust modules for numpy (already exists in octave version)
  * remixer where grains scrub the buffer at different rates but each mutes itself according to its dissonance
  * pure server-side CFDG
  * pure server-side pso flocking algorithm
  * pure server-side particle filter
  * auto sub maximising bassline thing, octavising oscillators until they are all in the right bandwidth
  * "futurising delay" - does JUST LESS than 1 bar
  * angklung attack-oriented granular synth
  * marsenator that marsenates samples
  * notestream app, streaming chords in different patterns to different midi channels
  * polyrhythm as highlighting different cycles within a rhythmn cascade
  * granular flanger with nice tuning options
  * automatic synth-tracking eye-candy for grammarthing
  * (phrase) phrase sampler
  * microproducer effect synths
  * 2d effects crossfade bus, maybe with a well-like dropp it in doppler thing. sountoirs of lfos are revealed over time
  * 3D effect scape through which we drop sound grains that rewrite and recolour themslves.
  * regression of mapping from sound to synth parameters by hearing and comparing resynthesised version with delayed or recorded version, enveloped appropriately.
* patch MixerChannel to be very simple
  * without automation, dependency management, playing methods, resumption etc
  * with gui and fader
  * with level meter http://doc.sccode.org/Classes/LevelIndicator.html