(
SynthDef(\jack, {
	|i_in,
	 i_out|
	Out.ar(i_out, In.ar(i_in, 1));
}).send(s);

SynthDef(\jack_2, {
	|i_in,
	 i_out|
	Out.ar(i_out, In.ar(i_in, 2));
}).send(s);

SynthDef(\jack_3, {
	|i_in,
	 i_out|
	Out.ar(i_out, In.ar(i_in, 3));
}).send(s);

SynthDef(\jack_4, {
	|i_in,
	 i_out|
	Out.ar(i_out, In.ar(i_in, 4));
}).send(s);

SynthDef(\particle, {
	|cacophonyInToMe,
	 out = 0,
	 discernmentTime=10,	//resp time in seconds
	 buffer = 0,
	 gate = 1,
	 pitch = 1,  //first of the synth parameters
	 pointer = 0.0,
	 gain = -12.0,
	 pan = 0.0,
	 windowSize = 0.1,
	 filtFreq = 600.0,		
	 rQ = 0.5|
	//synth vars
	var env, outMix, outMono;
	//analysis vars
	var iSaid, weSaid, discernibility, crossPresence, myPresence, overallPresence, riseTime, fallTime;
	var eps = 2.0e-07;
	discernmentTime = discernmentTime; 
	env = EnvGen.kr(
	  Env.asr(discernmentTime/2, 1, discernmentTime/2, 'linear'),
	  gate: gate,
	  doneAction: 2);
	outMono = Resonz.ar(
		Warp1.ar(
		    1,			// num channels (Class docs claim only mono works)
		    buffer,		// buffer
		    pointer,		// start pos
		    pitch,			// pitch shift
		    windowSize,	// window size (sec?)
		    -1,			// envbufnum (-1=Hanning)
		    4,				// overlap
		    0.1,			// rand ratio
		    2,				// interp (2=linear)
		    gain.dbamp	// mul
		),
		filtFreq,
		rQ
	);
	outMix = Pan2.ar(
		in: outMono,	// in
		pos: pan,		// field pos
		level: env		// level
	);
	iSaid = DelayN.ar(outMono, ControlRate.ir.reciprocal, ControlRate.ir.reciprocal); //This is my voice (delayed by a vector). I will look for it in the output.
	Out.ar(out, outMix);		//I output it panned
	weSaid = InFeedback.ar(cacophonyInToMe);
	riseTime = discernmentTime/8;
	fallTime = discernmentTime;
	myPresence = A2K.kr(LagUD.ar(iSaid*iSaid, riseTime, fallTime));
//	myPresence.poll(Impulse.kr(discernmentTime.reciprocal), \me);
//	overallPresence = A2K.kr(LagUD.ar(Mix.ar(weSaid*weSaid), riseTime, fallTime));
//	overallPresence.poll(Impulse.kr(discernmentTime.reciprocal), \overall);
	crossPresence = A2K.kr(LagUD.ar(Mix.ar(iSaid*weSaid), riseTime, fallTime)); //correlate.
//	crossPresence.poll(Impulse.kr(discernmentTime.reciprocal), \cross);
	discernibility = 0.0.max(1.0 - (((crossPresence - myPresence)/(crossPresence)).squared));//scale by overallPresence?
//	discernibility.poll(Impulse.kr(discernmentTime.reciprocal), \disc).abs;
	SendTrig.kr(LFPulse.kr((discernmentTime.reciprocal)/2),0,discernibility); //FASTER than discernment time to reduce jitter worries.
}, [\ir, \ir, \ir, nil, nil, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]).send(s);

o=Proto({
	~synth = nil;
	~myServer = nil;
	~myBuf = nil;
	~mainOut = nil;
	~myCacophonyBus = nil;
	~discernibility = 0.0;
	~responder = 0;
	~globalPresence = nil;
	~chromosome = nil;
	~particleGroup=nil;
	~discernmentTime=10;
	~discernmentChecker = nil;
	~age=0;

	~updateChromosome = { |chrom=nil|
		if (chrom.isNil()) {chrom = Array.fill(7, {1.0.rand2});};
		//["chrom", chrom, chrom[0], chrom[0].linexp(0.0,  1.0,   0.1,     10.0)].postln;
		~chromosome = chrom;
		~synthesize.(
			chrom[0].linexp(-1.0,  1.0,   0.1,     10.0), //pitch
			chrom[1].linlin(-1.0,  1.0,   0.0,      1.0), //pointer
			chrom[2].linlin(-1.0,  1.0, -36.0,      0.0), //gain
			chrom[3].linlin(-1.0,  1.0,  -1.0,      1.0), //pan
			chrom[4].linexp(-1.0,  1.0,   0.01,    10.0), //windowSize
			chrom[5].linexp(-1.0,  1.0,  40.0,  12000.0), //filtFreq
			chrom[6].linexp(-1.0,  1.0,   0.01,     1.0)  //rQ
		);
		//return self, or we get the synthdef back
		currentEnvironment;
	};
	/* This as a constructor. See
	http://article.gmane.org/gmane.comp.audio.supercollider.user/71449 */
	~setUp = {|server,
			myCacophonyBus,
			out,
			particleGroup,
			buffer,
			globalPresence,
			chromosome,
			discernmentTime=10|
		~myServer=server;
		~mainOut=out;
		~myBuf=buffer;
		~globalPresence=globalPresence;
		~myCacophonyBus=myCacophonyBus;
		~particleGroup=particleGroup;
		~discernmentTime=discernmentTime;
		~age=0;
		~synth=Synth.new(\particle, [\myCacophonyBus, ~myCacophonyBus, \out, ~mainOut, \discernmentTime, ~discernmentTime], ~particleGroup);
		NodeWatcher.register(~synth, true);
		/* how you set up callbacks with sane binding:
		http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Event-and-prototypes-tp6208222p6226707.html */
		~responder = OSCpathResponder(
			~myServer.addr,
			['/tr', ~synth.nodeID, 0],
			inEnvir { |t,r,msg| msg[3].isNaN.not.if({~discernibility=msg[3];});}
		);
		~responder.add();
		~updateChromosome.(chromosome);
		currentEnvironment;
	};
	~synthesize = { |pitch = 1,
			pointer = 0.0,
			gain = -12.0,
			pan=0.0,
			windowSize=0.1,
			filtFreq=64.0,
			rQ=0.5|
		//["pitch, pointer, gain, pan, windowSize, filtFreq, rQ", pitch, pointer, gain, pan, windowSize, filtFreq, rQ].postln;
		~synth.set(
			\pitch, pitch,
			\pointer, pointer,
			\gain, gain,
			\pan, pan,
			\windowSize, windowSize,
			\filtFreq, filtFreq,
			\rQ, rQ
		);
//		~synth.run(true);
	};
	~tearDown = {
		~synth.release();
		~responder.remove();
	};
	~tick = {
		~age= ~age+1;
	};
	~mutated = { |chromosome|
		//a mutation function. this feels like it should be set from a library of mutators. one day.
		// it returns a perturbed chromosome, but does not modify this in place.
		(chromosome.isNil()).if({chromosome = ~chromosome;});
		~chromosome.collect({|v| (v + gauss(0.0, 0.1)).softclip(); });
	}
});

n=Proto({
	//A factory and manager for a bunch of particles
	~particles = nil;
	~population = nil;
	~myServer = nil;
	~myBuf = nil;
	~mainOut = nil;
	~myCacophonyBus = nil;
	~cacophonyOut = nil;
     ~particleGroup=nil;
	~discernmentTime=10;

	~setUp = {|server,
			out,
			buffer=nil,
			population=10,
			discernmentTime=10|
		~myServer=server;
		~mainOut=out;
		~particles=List();
		~population=population;
		~myCacophonyBus = Bus.audio(s, 2); 
		~cacophonyOut = Synth.new(\jack_2, [\i_in, ~mainOut, \i_out, ~myCacophonyBus]);
		~particleGroup=Group.new(~myServer);
		~globalPresence = Bus.audio(s,1);
		if (buffer.isNil()) {
			buffer = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");};
		~myBuf = buffer;
		~discernmentTime=discernmentTime;
		while ({~particles.size<~population}, {~addParticle.();});
		SystemClock.sched(discernmentTime,
			inEnvir {
				~tend.();
				"tending".postln;
				~discernmentTime;
			}
		);
		currentEnvironment;
	};
	~tearDown = {
		while ({~particles.size>0}, {~removeParticle.();});
		~particleGroup.free();
		~myCacophonyBus.free();
		~globalPresence.free();
		~myBuf.free();
	};
	~addParticle = {|chromosome|
		var particle;
		["creating new particle with discernmentTime", ~discernmentTime];
		particle = o.copy.setUp(
		  ~myServer,
		  ~myCacophonyBus,
		  ~outs,
		  ~particleGroup,
		  ~myBuf,
		  nil, //globalPresence
		  nil, //chromosome
		  ~discernmentTime
		);
		~particles.add(particle);
		particle.updateChromosome(chromosome);
	};
	~randomizeAll = {|indices=nil|
		if (indices.isNil()) {indices=(0..(~particles.size-1));};
		indices.do({|idx|
			(~particles[idx]).postln;
			(~particles[idx]).updateChromosome(nil);});
	};
	~removeParticle = {|idx=0|
		["remove", idx, ~particles[idx]];
		(~particles[idx]).tearDown();
		~particles.removeAt(idx);
	};
	~tend = {
		var weakestLinks, mean, survivableDiscernability, newChromosome, discernibilities;
		~particles.do({|p| p.tick();});
		//survivableDiscernability = (~particles.size * 2).reciprocal;
		survivableDiscernability = (~particles.size).reciprocal;
		["survivableDiscernability", survivableDiscernability].postln;

		//indices of killable, unfit particles
		weakestLinks = ~particles.collect({|p, i|
			((p.age > 5).and(p.discernibility < survivableDiscernability)).if(i);
		}).removeEvery([nil]).reverse;
		["weakestLinks", weakestLinks].postln;
		weakestLinks.do({|i|
			["killing", i, ~particles[i].discernibility].postln;
			~removeParticle.(i);
		});
		discernibilities = ~particles.collect({|p| p.discernibility;});
		["mean", discernibilities.mean(), "stddev", discernibilities.stdDev()].postln;
		//add an even chance of getting a random mutant
		discernibilities = discernibilities.add(survivableDiscernability);		discernibilities = discernibilities/(discernibilities.sum);
		weakestLinks.do({|i|
			var parent, parentChromosome, newParticle;
			var exNihilo = false;
			//this will always choose an existing one, since the new particles go at the end
			parent = ~particles.wchoose(discernibilities);
			if (parent.isNil(), {
				parentChromosome=nil; exNihilo=true;
				}, {
				parentChromosome = parent.mutated();
			});
			["birthing", i, discernibilities, exNihilo].postln;
			newParticle = ~addParticle.(parentChromosome);
			//["new", newParticle.chromosome, "old", parentChromosome].postln;
		});
	};
});
)

(
s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;
~globalOuts = Bus.new(\audio, 0, 2);
//~swarmOuts = Bus.new(\audio, 0, 2); //compress swarm separately?
q=n.copy.setUp(s, ~globalOuts, nil, 1);
q=n.copy.setUp(s, ~globalOuts, nil, 100, 1);
q=n.copy.setUp(s, ~globalOuts, nil, 20, 1);
q=n.copy.setUp(s, ~globalOuts, nil, 20, 0.1);
q.randomizeAll();
q.particles[8].discernmentTime;
q.discernmentTime;
q.particles.size;
q.discernmentTime;
q.tearDown();
)

(
s.scope;
Quarks.gui;
f.isNaN.not.if({'notNAN';}, {'NAN';});
)

/*
TODO
====

* discernment
  * find better autocorrelation that does not favour all converging to one thing.
  * need to compensate for different weighting of spectral bands in the autocorrelation thingy.
  * find a better survivable discernability heuristic
  * weight two different channels oppositely, as predator or prey signals
  * how can we favour bass?
  * how can we favour rhythmic evolution? (by favouring spectral variance over time?)
  * how can we not favour white noise? (see above)
  * allow different discernibilityTimes?
  * clip discernability function as a way of killing agents
  * consider doing everything in fourier space?
    * Or the cepstral domain?
  * visualise spectrograph, or signal scope or something to distinguish what discernment is doing
  * think in terms of linear regression
* optimisation
  * share global cacophony calcs across all voices
* style
  * go to IdentityDictionaries for particle storage and hash/counter-named particles
  * switch to generating iterator Routines instead of generating temporary collections
  * get rid of this "my" business with member names
* niceties
  * have a global TempoClock to keep triggering discernibility tests, and pause if necessary
  * make populations archivable, serialisable etc
* sound
  * go from stereo to ambisonic, or something
  * volume control, sensitive to number of agents
  * add in LFOs
    * which means pushing param mapping inside synthdef
  * record into global buffers?
  * attach "species" to buffer
  * envelope birth and death
* evolution
  * crossover parentage
  * reproduce via mitosis
  * interpolate smoothly to new value
  * don't wait for death to reproduce, let the young drive out the old
  * give birth when sufficiently fit.
  * consider evolvability, and how to have a more robust chromosome.
  * evolve "evolvability" 
    * mutation rates per gene
    * or increments for offspring
  * create a library of crossover, selector and mutator functions
  * visualise chromosomes

*/