s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;

(
~outs = Bus.new(\audio, 0, 2);

SynthDef(\particle, {
	|fbBus,
	 out = 0,
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
	var iSaid, theySaid, discernibility, myPresence, overallPresence, discernmentTime;
	discernmentTime = 1; //resp time in seconds
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
	iSaid = LocalIn.ar(1);
	LocalOut.ar(outMono);	//This is my voice. I will look for it in the output.
	Out.ar(out, outMix);		//I output it panned
	//theySaid = InFeedback(fbBus);
	theySaid = iSaid;			//We don't have a feedback bus yet
	myPresence = A2K.kr(Lag.ar(iSaid*iSaid, discernmentTime));
	overallPresence = A2K.kr(Lag.ar(theySaid*theySaid, discernmentTime));
	discernibility = A2K.kr(Lag.ar(Mix.new(iSaid*iSaid), discernmentTime)); //autocorrelate.
	//A2K.kr(discernibility).poll;
	SendTrig.kr(LFPulse.kr(discernmentTime.reciprocal),0,discernibility);
}).send(s);


o=Proto({
	~synth = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~fbBus = nil;
	~discernibility = 0;
	~responder = 0;
	~globalPresence = nil;
	~chromosome = nil;

	/*if setUp is run lots,
	it leaks memory. So use this as a constructor, which is the mandated way. See
	http://article.gmane.org/gmane.comp.audio.supercollider.user/71449 */
	~updateChromosome = { |chrom|
		if (chrom.isNil) {chrom = Array.fill(7,{1.0.rand});};
		~chromosome = chrom;
		~synth.set(
			\pitch,		chrom[0].linexp(0.0,  1.0,   0.1,     10.0),
			\pointer,		chrom[1].linlin(0.0,  1.0,   0.0,      1.0),
			\gain,			chrom[2].linlin(0.0,  1.0, -30.0,      6.0),
			\pan,			chrom[3].linlin(0.0,  1.0,  -1.0,      1.0),
			\windowSize,	chrom[4].linexp(0.0,  1.0,   0.01,    10.0),
			\filtFreq,		chrom[5].linexp(0.0,  1.0,  40.0,  12000.0),
			\rQ, 			chrom[6].linexp(0.0,  1.0,   0.0,      1.0)
		);
		~synth.run(true);
	};
	~setUp = {|server,
			fbBus,
			out,
			buffer,
			globalPresence,
			chromosome|
		~myServer=server;
		~myOut=out;
		~myBuf=buffer;
		~globalPresence=globalPresence;
		~fbBus=fbBus;
		~synth=Synth.newPaused(\particle, [\fbBus, ~fbBus, \out, ~myOut]);
		NodeWatcher.register(~synth, true);
		~discernibility=0.0;
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
		["pitch", pitch].postln;
		~synth.set(
			\pitch, pitch,
			\pointer, pointer,
			\gain, gain,
			\pan, pan,
			\windowSize, windowSize,
			\filtFreq, filtFreq,
			\rQ, rQ
		);
		~synth.run(true);
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
	~fb = nil;

	~setUp = {|server,
			out,
			buffer=nil,
			population=10|
		~myServer=server;
		~myOut=out;
		~particles=List();
		~population=population;
		~fb = Bus.audio(s, 2); 
		~globalPresence = Bus.audio(s,1);
		if (buffer.isNil()) {
			buffer = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");};
		~myBuf = buffer;
		while ({~particles.size<~population}, {~addParticle.();});
		currentEnvironment;
	};
	~tearDown = {
		while ({~particles.size>0}, {~removeParticle.();});
		~fb.free();
		~globalPresence.free();
		~myBuf.free();
	};
	~addParticle = {|chromosome|
		var particle;
		particle = o.copy.setUp(~myServer, ~fb, ~outs, ~myBuf);
		~particles.add(particle);
		particle.synthesize();
	};
	~removeParticle = {|i=0|
		["remove", i, ~particles[i]];
		(~particles[i]).tearDown();
		~particles.removeAt(i);
	};
});
)

(
p.tearDown();
//p=o.copy.setUp(s, ~fb, ~outs, ~buf);
q=n.copy.setUp(s, ~outs);
q.tearDown();
p.setUp(s, ~fb, ~outs, ~buf);
p.synthesize();
p.synthesize(4);
p.discernibility;
p.responder.remove();
)

x = Synth(\particle, [\fbBus, ~fb, \out, ~outs, \pitch, 1, \pointer, 0.0, \gain, -20, \windowSize, 1]);
x.release();
x = Synth(\particle, [\fbBus, ~fb, \out, ~outs, \pitch, 1, \pointer, 0.33, \gain, -20, \rQ, 1]);
x = Synth(\particle, [\fbBus, ~fb, \out, ~outs, \pitch, 1.5]);
x = Synth(\particle, [\fbBus, ~fb, \out, ~outs, \pitch, 2]);

x.free;
/*
TODO
====

* do discernibility calcs at kr (after autocorrelation, at least)
* need discernibility measured against general RMS volume
* go from stereo to ambisonic
* use Delay instead of LocalIn. (maybe faster?)
*/