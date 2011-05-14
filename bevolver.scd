s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;

(
~outs = Bus.new(\audio, 0, 2);
~fb = Bus.audio(s, 2); 
~globalPresence = Bus.audio(s,1);
~buf = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");


SynthDef(\particle, {
	|fbin,
	 out = 0,
	 buffer = 0,
	 gate = 1,
	 pitch = 1,
	 pointer = 0.0,
	 gain = -12.0,
	 pan = 0.0,
	 windowSize = 0.1,
	 freqNote = 64.0,
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
		freqNote.midicps,
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
	//theySaid = InFeedback(fbin);
	theySaid = iSaid;			//We don't have a feedback bus yet
	myPresence = A2K.kr(Lag.ar(iSaid*iSaid, discernmentTime));
	overallPresence = A2K.kr(Lag.ar(theySaid*theySaid, discernmentTime));
	discernibility = A2K.kr(Lag.ar(Mix.new(iSaid*iSaid), discernmentTime)); //autocorrelate.
	//A2K.kr(discernibility).poll;
	SendTrig.kr(LFPulse.kr(discernmentTime.reciprocal),0,discernibility);
}).send(s);
)

(
o=Proto({
	~synth = nil;
	~myServer = nil;
	~myBuf = nil;
	~myOut = nil;
	~fbin = nil;
	~discernibility = 0;
	~responder = 0;
	//if setUp is run lots, it leaks memory. just so you know.
	~setUp = { |server,
			fbin,
			out=0,
			buffer|
		~myServer=server ? s;
		~myOut=out;
		~myBuf=buffer;
		~fbin=fbin;
		~synth=Synth.newPaused(\particle, [\fbin, ~fbin, \out, ~myOut]);
		NodeWatcher.register(~synth, true);
		~discernibility=0.0;
		/* how you set up callbacks with sane binding:
		http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Event-and-prototypes-tp6208222p6226707.html */
		~responder = o = OSCpathResponder(~myServer.addr, ['/tr', ~synth.nodeID, 0],
			inEnvir { |t,r,msg|
				if (msg[1] == ~synth.nodeID) {
					~discernibility=msg[3];
		    	};
			};
		).add;

	};
	~synthesize = { |pitch = 1,
			pointer = 0.0,
			gain = -12.0,
			pan=0.0,
			windowSize=0.1,
			freqNote=64.0,
			rQ=0.5|
		pitch.postln;
		~synth.set(
			\pitch, pitch,
			\pointer, pointer,
			\gain, gain,
			\windowSize, windowSize,
			\freqNote, freqNote,
			\rQ, rQ
		);
		~synth.run(true);
	};
	~tearDown ={
		~synth.release();
		~responder.remove();
	};
});
)

(
p.tearDown();
p=o.copy();
p.setUp(s, ~fb, ~outs, ~buf);
p.synthesize();
p.synthesize(4);
p.discernibility;
p.synth.nodeID;
OSCResponderNode
p.synth.responder;
)

x = Synth(\particle, [\fbin, ~fb, \out, ~outs, \pitch, 1, \pointer, 0.0, \gain, -20, \windowSize, 1]);
x.release();
x = Synth(\particle, [\fbin, ~fb, \out, ~outs, \pitch, 1, \pointer, 0.33, \gain, -20, \rQ, 1]);
x = Synth(\particle, [\fbin, ~fb, \out, ~outs, \pitch, 1.5]);
x = Synth(\particle, [\fbin, ~fb, \out, ~outs, \pitch, 2]);
x.free;
/*
TODO
====

* do discernibility calcs at kr (after autocorrelation, at least)
* need discernibility measured against general RMS volume
* go from stereo to ambisonic

*/