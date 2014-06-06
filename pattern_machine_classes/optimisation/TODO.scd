/**************************
 * TODO - PSO synths
 **************************

* GUI
    * input and output level mix
		* merge mixerchannelpso in to make the particleswarm thing be a little more friendly
    * "explode" button, scattering the chromosomes
    * pluck individuals out and let them wander back to the swarm
* update the target to be an evolving synth
	* hot swap tracking input
	* Shift param ranges live
* more interesting objective functions:
	* match a pitch-shifted version of the input
	* or a delayed version
	* raw cepstral measures to favour harmonicity
* meta-optimisation of the meta-heuristic.
	* annealing schedule
	* detecting the need to update noise parameters
		(e.g. decreasing without changing)
	* optional meta-optimising operator
	* remember near-global maxima so I know when I've drifted off.
* specific sample synth player
	* How can this sound sparser? Reward silence?
	* some kind of nonlinear feedback situation?
	* sample recording
* go to MOL ("many optimising liaisons")
	* choose random peer as neighbour each time
	* update only one at each time
* visualise this using Quartz Composer
    * send particle positions over OSC
* update SynthController to have its params accessed through a controller
  so that, e.g. clockrate can change on the fly
* can I get rid of the PSSynthDefPhenotypeFactory now that I have extraSynthArgs in the controller class?
* should I put some methods in there to handle lagtime on the controller?

 **************************
 * TODO - PHENOSYNTH
 **************************

* infrastructure

  * Make the fitness cooker API simpler to develop for and test. Plain lists, rather
    than maps, would be better.
  * get rid of SynthPhenotype. completely useless.
  * get rid of scoreCooker for the simplest case of converting nearness to distance
  * cause fitness thingies to automatically report fitness, without waiting for /get
    messages
  * reimplement internal population wrangling using ObjectTable.
  * listensynthdefs are primitive compared to comparesynthdefs. Bring them up to date
  * optionally recycle listeners, since deleting and creating them is CPU-heavy
  * fix operation when numChannels>1 (at the moment there are bus allocation
    failures and misc screencruft in that case)
  * allow custom evolvability mappings and starting chromosome.
  * plots and histograms of values

    * send data over OSC to some nonparametric estimator somewhere and plot that.

  * Fix leaks

    * ensure Groups are also freed.
    * use Synth doneActions and per-listener groups to free all resources on
      demand
    * remove debugging loggers

  * fitness improvements

    * work out the stats for proper birth/death hazard processes, fitness-weighted

  * better fitness metrics for listening

    * time-delayed correlation?
    * amplitude-weighted convolution
    * some fancy wavelet shit?
    * optimise out the spectral-domain transforms of the master signal in the fitness business
    * FFT_wide is not very good. If one signal is low frequency the entire thing
      has a low distance, lower even than a perfect match. (Why?) Even the narrowband
      FFT weights rates low-frequency signals implausibly similar. (try wintype:1?)

  * sort out the interactions of all these different tick rates and periods.
  * Handle "free controls", values that are passed in live by the user, or
    external LFOs or data in general. (esp for triggers)
  * serialize phenotypes to disk so evolution can be resumed.
  * chromosome management

    * create handy new classes to cast as needed between int, bits, float. (UnitFloat,
      and a Chromosome class.)

  * Check for extinction and restock.

* Give the faintest of indications that I do care about tests
* document classes
* provide examples

  * examples of using this to do vanilla non-accumulating, genotype-style selection

* Crazy schemes happening no time soon.

    * support geographical separation of populations to aid speciation
    * augment all operator protocols to pass in the PSIsland instance, or some other global
      state
    * for non-realtime use, optionally conduct evolution in a Routine which yields from
      time to time to facilitate responsiveness
    * Have GUI for phenotypes
    * allow tagging - speciation based on acquiring the right "tag" variable.
    * go to generalised Feynman-Kac particle filtering methods
	  http://www.math.u-bordeaux1.fr/~delmoral/simulinks.html
    * allow a seed-bank supporting far more genomes than can be simultaneously
      simulated in DSP. (I.e. keep a much larger population, but only simulate a part
      of them at once)

* multi-server controllers
* my earswarm

  * normalise fitness gain w/respect to energy expenditure (i.e. amplitude)
  * evolve a map between input and output to teach creatures to produce maximally
    versatile responses to diverse signals
  * sampling, playback
  * LFOs

    * support creatures which vocalise only sporadically (saving CPU, or at
      least saving earspace)

  * give lifespans using the exponential distribution \lambda \e ^{-\lambda \e}
  * doesn't apply ATM but might with different regimes:

    * scale birthRate and deathRate so that they fit eventual fitness
    * reseed population when they all die
*/
