s.boot;

(
~chanz=2;
b = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");

SynthDef(\warp, {|pitch = 1, pointer = 0.0, gain = -12.0, pan=0.0, windowSize=0.1 |
	//synth vars
	var env, buffer, outmix, outmono;
	//analysis vars
	var i_said, they_said, discernability, discernmentTime;
	discernmentTime = 0.1; //resp time in seconds
	buffer = b;
	env = EnvGen.kr(Env([0.001, 1, 1, 0.001], [0.1, 14, 0.9], 'exp'), doneAction: 2);
	outmono = Warp1.ar(
	    1,          // num channels (hmm - class claims only mono works)
	    buffer,     // buffer
	    pointer,    // start pos
	    pitch,      // pitch shift
	    windowSize, // window size (sec?)
	    -1,         // envbufnum (-1=Hanning)
	    4,          // overlap
	    0.1,        // rand ratio
	    2,          // interp (2=linear)
	    gain.dbamp  // mul
	);
	outmix = PanAz.ar(
		~chanz, 	// numChans
		outmono, 	// in
		pan,      // field pos
		env,		// level
		2			// width
	);
	i_said = LocalIn.ar(1);
	LocalOut.ar(outmono);    //This is my voice. I will look for it in the output.
	Out.ar(0, outmix);       //I output it panned
	they_said = i_said;      //We don't have a good feedback bus yet
	discernability = Lag.ar(Mix.new(i_said*i_said), discernmentTime); //autocorrelate.
	A2K.kr(discernability).poll;
	SendTrig.kr(LFPulse.kr(discernmentTime.reciprocal),0,discernability);
}).send(s);

// register to receive this message
OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	[time,responder,msg].postln;
}).add;
)

x = Synth(\warp, [\pitch, 1, \pointer, 0.0, \gain, -20, \windowSize, 1]);
x = Synth(\warp, [\pitch, 1, \pointer, 0.33, \gain, -20]);
x = Synth(\warp, [\pitch, 1.5]);
x = Synth(\warp, [\pitch, 2]);
x.free;

/*

TODO
====

* do discernability calcs at kr (after autocorrelation, at least)


*/