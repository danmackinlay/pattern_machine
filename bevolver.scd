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
	|myCacophonyBus,
	 out = 0,
	 discernmentTime=10,	//resp time in seconds
	 buffer = 0,
	 gate = 1,
	 pitch = 1,
	 pointer = 0.0,
	 gain = -12.0,
	 pan = 0.0,
	 windowSize = 0.1,
	 filtFreq = 600.0,		
	 rQ = 0.5|
	//synth vars
	var env, outMix, outMono;
	//analysis vars
	var iSaid, weSaid, discernibility, crossPresence, myPresence, overallPresence;
	var eps = 2.0e-07;
	env = EnvGen.kr(
	  Env.cutoff(1, 1, 'linear'),
	  gate: gate,
	  doneAction: 2);
	outMono = Resonz.ar(
		Warp1.ar(
		    1,			// num channels (Class claims only mono works)
		    buffer,		// buffer
		    pointer,		// start pos
		    pitch,		// pitch shift
		    windowSize,	// window size (sec?)
		    -1,			// envbufnum (-1=Hanning)
		    4,			// overlap
		    0.1,			// rand ratio
		    2,			// interp (2=linear)
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
	weSaid = InFeedback.ar(myCacophonyBus);
	myPresence = A2K.kr(Lag.ar(iSaid*iSaid, discernmentTime));
//	myPresence.poll(Impulse.kr(discernmentTime.reciprocal), \me);
	overallPresence = A2K.kr(Lag.ar(Mix.ar(weSaid*weSaid), discernmentTime));
//	overallPresence.poll(Impulse.kr(discernmentTime.reciprocal), \overall);
	crossPresence = A2K.kr(Lag.ar(Mix.ar(iSaid*weSaid), discernmentTime)); //correlate.
//	crossPresence.poll(Impulse.kr(discernmentTime.reciprocal), \cross);
	discernibility = (crossPresence.abs + eps)/((overallPresence*myPresence+eps).sqrt);
//	discernibility.poll(Impulse.kr(discernmentTime.reciprocal), \disc).abs;
	SendTrig.kr(LFPulse.kr((discernmentTime.reciprocal)/2),0,discernibility); //FASTER than discernment time to reduce jitter worries.
}, [\ir, \ir, \ir, nil, nil, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]).send(s);


o=Proto({
	~synth = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~myCacophonyBus = nil;
	~discernibility = 0.0;
	~responder = 0;
	~globalPresence = nil;
	~chromosome = nil;
	~particleGroup=nil;
	~discernmentTime=10;
	~discernmentChecker = nil;
	~age=0;

	/*if setUp is run lots on an existing object
	it leaks memory. So use this as a constructor, which is the mandated way. See
	http://article.gmane.org/gmane.comp.audio.supercollider.user/71449 */
	~updateChromosome = { |chrom=nil|
		if (chrom.isNil()) {chrom = Array.fill(7, {1.0.rand});};
		//["chrom", chrom, chrom[0], chrom[0].linexp(0.0,  1.0,   0.1,     10.0)].postln;
		~chromosome = chrom;
		~synthesize.(
			chrom[0].linexp(0.0,  1.0,   0.1,     10.0), //pitch
			chrom[1].linlin(0.0,  1.0,   0.0,      1.0), //pointer
			chrom[2].linlin(0.0,  1.0, -36.0,      0.0), //gain
			chrom[3].linlin(0.0,  1.0,  -1.0,      1.0), //pan
			chrom[4].linexp(0.0,  1.0,   0.01,    10.0), //windowSize
			chrom[5].linexp(0.0,  1.0,  40.0,  12000.0), //filtFreq
			chrom[6].linexp(0.0,  1.0,   0.01,     1.0)  //rQ
		);
	};
	~setUp = {|server,
			myCacophonyBus,
			out,
			particleGroup,
			buffer,
			globalPresence,
			chromosome,
			discernmentTime=10|
		~myServer=server;
		~myOut=out;
		~myBuf=buffer;
		~globalPresence=globalPresence;
		~myCacophonyBus=myCacophonyBus;
		~particleGroup=particleGroup;
		~discernmentTime=discernmentTime;
		~age=0;
//		~synth=Synth.newPaused(\particle, [\myCacophonyBus, ~myCacophonyBus, \out, ~myOut], ~particleGroup);
		~synth=Synth.new(\particle, [\myCacophonyBus, ~myCacophonyBus, \out, ~myOut, \discernmentTime, ~discernmentTime], ~particleGroup);
		NodeWatcher.register(~synth, true);
		~discernibility;
		/* how you set up callbacks with sane binding:
		http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Event-and-prototypes-tp6208222p6226707.html */
		~responder = OSCpathResponder(
			~myServer.addr,
			['/tr', ~synth.nodeID, 0],
			inEnvir { |t,r,msg| ~discernibility=msg[3];}
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
});

n=Proto({
	//A factory and manager for a bunch of particles
	~particles = nil;
	~population = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~myCacophonyBus = nil;
	~myJack = nil;
     ~particleGroup=nil;
	~discernmentTime=10;

	~setUp = {|server,
			out,
			buffer=nil,
			population=10,
			discernmentTime=10|
		~myServer=server;
		~myOut=out;
		~particles=List();
		~population=population;
		~myCacophonyBus = Bus.audio(s, 2); 
		~myJack = Synth.new(\jack_2, [\i_in, ~myOut, \i_out, ~myCacophonyBus]);
		~particleGroup=Group.new(~myServer);
		~globalPresence = Bus.audio(s,1);
		if (buffer.isNil()) {
			buffer = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");};
		~myBuf = buffer;
		while ({~particles.size<~population}, {~addParticle.();});
		~discernmentTime=discernmentTime;
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
		particle = o.copy();
		particle.setUp(~myServer, ~myCacophonyBus, ~outs, ~particleGroup, ~myBuf, ~discernmentTime);
		~particles.add(particle);
		particle.updateChromosome(chromosome);
	};
	~randomize = {|indices=nil|
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
		var weakestLinks, mean, survivableDiscernability;
		~particles.do({|p| p.tick();});
		survivableDiscernability = (~particles.size * 2).reciprocal;
		["survivableDiscernability", survivableDiscernability].postln;
		mean = ~particles.collect({|p| p.discernibility;}).mean();
		//indices of killable, unfit particles
		weakestLinks = ~particles.collect({|p, i|
			["checking", p, i, p.discernibility, p.age].postln;
			((p.age > 10).and(p.discernibility < survivableDiscernability)).if(i);
		}).removeEvery([nil]).reverse;
		["weakestLinks", weakestLinks].postln;
		["mean", mean].postln;
		weakestLinks.do({|i|
			["killing", i];
			~removeParticle.(i);
			~addParticle.();
		});
	};
});
)

(
s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;
~outs = Bus.new(\audio, 0, 2);
q=n.copy.setUp(s, ~outs, nil, 1);
q=n.copy.setUp(s, ~outs, nil, 100, 1);
q=n.copy.setUp(s, ~outs, nil, 10, 1);
q=n.copy.setUp(s, ~outs, nil, 20, 0.1);
q.randomize();
q.getDiscernibility();
q.tearDown();
)

(
s.scope;
Quarks.gui;
)

/*
TODO
====

* need to compensate for different weighting of spectral bands in the autocorrelation thingy.
* switch to generating iterator Routines instead of generating temporary collections
* find a better survivable discernability heuristic
* consider doing everything in fourier space?
* go from stereo to ambisonic, or something
* volume control, sensitive to number of agents
* clip discernability function as a way of killing agents
* add in LFOs
* weight two different channels oppositely, as predator or prey signals
* record sound samples
* crossover parentage
* change set lag time to 0 initially, then shift after one tick
* how can we favour rhythmic evolution? (by favouring spectral variance over time?)
* how can we not favour white noise? (see above)
* give birth when sufficiently fit.
* how can we favour bass?
* have a global TempoClock to keep triggering discernibility tests, and pause if necessary
* allow different discernibilityTimes?
* record into global buffers?
* consider evolvability, and how to have a more robust chromosome.
* make populations archivable, serialisable etc
* evolve "evolvability" 
  * mutation rates per gene
  * or increments for offspring
* go to IdentityDictionaries for particle storage and hash/counter-named particles
*/