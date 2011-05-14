s.boot;
s.options.numOutputBusChannels;
s.options.numInputBusChannels;

(
~chanz=2;
~outs = Bus.new(\audio, 0, ~chanz);
~fb = Bus.audio(s, ~chanz); 

~b = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");


SynthDef(\particle, {
	|fbin,
	 out=0,
	 gate = 1,
	 pitch = 1,
	 pointer = 0.0,
	 gain = -12.0,
	 pan=0.0,
	 windowSize=0.1,
	 freqNote=64.0,
	 rQ=0.5|
	//synth vars
	var env, buffer, outMix, outMono;
	//analysis vars
	var iSaid, theySaid, discernability, myPresence, overallPresence, discernmentTime;
	discernmentTime = 1; //resp time in seconds
	buffer = b;
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
	outMix = PanAz.ar(
		~chanz,	// numChans
		outMono,	// in
		pan,		// field pos
		env,		// level
		2			// width
	);
	iSaid = LocalIn.ar(1);
	LocalOut.ar(outMono);	//This is my voice. I will look for it in the output.
	Out.ar(out, outMix);		//I output it panned
	//theySaid = InFeedback(fbin);
	theySaid = iSaid;			//We don't have a good feedback bus yet
	myPresence = A2K.kr(Lag.ar(iSaid*iSaid, discernmentTime));
	overallPresence = A2K.kr(Lag.ar(theySaid*theySaid, discernmentTime));
	discernability = A2K.kr(Lag.ar(Mix.new(iSaid*iSaid), discernmentTime)); //autocorrelate.
	//A2K.kr(discernability).poll;
	SendTrig.kr(LFPulse.kr(discernmentTime.reciprocal),0,discernability);
}).send(s);

// register to receive this message
OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	[time,responder,msg].postln;
}).add;
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

* do discernability calcs at kr (after autocorrelation, at least)
* need discernability measured against general RMS vaolume

*/