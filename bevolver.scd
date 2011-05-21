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
	|arFbBus,
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
	discernmentTime = 1; 
	env = EnvGen.kr(
	  Env.cutoff(1, 1, 'linear'),
	  gate: gate,
	  doneAction: 2);
	outMono = Resonz.ar(
		Warp1.ar(
		    1,				// num channels (Class claims only mono works)
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
	weSaid = InFeedback.ar(arFbBus);
	myPresence = A2K.kr(Lag.ar(iSaid*iSaid, discernmentTime, add: eps));
	myPresence.poll(Impulse.kr(discernmentTime.reciprocal), \me);
	overallPresence = A2K.kr(Lag.ar(Mix.ar(weSaid*weSaid), discernmentTime, add: eps));
	overallPresence.poll(Impulse.kr(discernmentTime.reciprocal), \overall);
	crossPresence = A2K.kr(Lag.ar(Mix.ar(iSaid*weSaid), discernmentTime)); //correlate.
	crossPresence.poll(Impulse.kr(discernmentTime.reciprocal), \cross);
	discernibility = crossPresence/((overallPresence*myPresence).sqrt);
	discernibility.poll(Impulse.kr(discernmentTime.reciprocal), \disc).abs;
	SendTrig.kr(LFPulse.kr(discernmentTime.reciprocal),0,discernibility);
}, [\ir, \ir, \ir, nil, nil, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]).send(s);


o=Proto({
	~synth = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~arFbBus = nil;
	~discernibility = 0.0;
	~responder = 0;
	~globalPresence = nil;
	~chromosome = nil;
	~particleGroup=nil;
	~discernmentTime=10;

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
			chrom[2].linlin(0.0,  1.0, -30.0,      6.0), //gain
			chrom[3].linlin(0.0,  1.0,  -1.0,      1.0), //pan
			chrom[4].linexp(0.0,  1.0,   0.01,    10.0), //windowSize
			chrom[5].linexp(0.0,  1.0,  40.0,  12000.0), //filtFreq
			chrom[6].linexp(0.0,  1.0,   0.01,     1.0)  //rQ
		);
	};
	~setUp = {|server,
			arFbBus,
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
		~arFbBus=arFbBus;
		~particleGroup=particleGroup;
		~discernmentTime=discernmentTime;
//		~synth=Synth.newPaused(\particle, [\arFbBus, ~arFbBus, \out, ~myOut], ~particleGroup);
		~synth=Synth.new(\particle, [\arFbBus, ~arFbBus, \out, ~myOut, \discernmentTime, ~discernmentTime], ~particleGroup);
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
});

n=Proto({
	//A factory and manager for a bunch of particles
	~particles = nil;
	~population = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~myFb = nil;
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
		~myFb = Bus.audio(s, 2); 
		~myJack = Synth.new(\jack_2, [\i_in, ~myOut, \i_out, ~myFb]);
		~particleGroup=Group.new(~myServer);
		~globalPresence = Bus.audio(s,1);
		if (buffer.isNil()) {
			buffer = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");};
		~myBuf = buffer;
		while ({~particles.size<~population}, {~addParticle.();});
		currentEnvironment;
	};
	~tearDown = {
		while ({~particles.size>0}, {~removeParticle.();});
		~particleGroup.free();
		~myFb.free();
		~globalPresence.free();
		~myBuf.free();
	};
	~addParticle = {|chromosome|
		var particle;
		particle = o.copy();
		particle.setUp(~myServer, ~myFb, ~outs, ~particleGroup, ~myBuf, ~discernmentTime);
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
});
)

(
s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;
~outs = Bus.new(\audio, 0, 2);

s.scope;
q=n.copy.setUp(s, ~outs, nil, 1);
q=n.copy.setUp(s, ~outs);
q.randomize();
q.tearDown();
q.particles[0].discernibility;
q.particles[3].responder;
q.fb;
q.out;
p.setUp(s, ~fb, ~outs, ~buf);
p.synthesize();
p.synthesize(4);
p.discernibility;
p.responder.remove();
s.scope;
Quarks.gui;
j=5; (1..j);
)

/*
TODO
====

* do discernibility calcs at kr (after autocorrelation, at least)
* need discernibility measured against general RMS volume
* need to compensate for different weighting of spectral bands in the autocorrelation thingy.
* rename feedback to be "cacophony"
* consider doing everything in fourier space?
* go from stereo to ambisonic
* use Delay instead of LocalIn. (maybe faster?)
*/