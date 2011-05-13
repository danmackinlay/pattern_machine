s.boot;

(
~chanz=2;
b = Buffer.read(s, "/Users/dan/Library/Application Support/Ableton/Library/Samples/tests/cariboutesque.aif");

SynthDef(\warp, {arg pitch = 1;
	//synth vars
	var pointer, env, envbuf, dir, buffer, outmix, outmono;
	//analysis vars
	var i_said, they_said, loudness, window_time;
	//window = ControlDur.ir;
	window_time = 0.1; //resp time in seconds
	envbuf = -1;
	pointer = 0;
	buffer = 0;
	env = EnvGen.kr(Env([0.001, 1, 1, 0.001], [0.1, 14, 0.9], 'exp'), doneAction: 2);
	outmono = Warp1.ar(1, buffer, pointer, pitch, 0.1, envbuf, 8, 0.1, 2);
	outmix = PanAz.ar(
		~chanz, 	// numChans
		outmono, 	// in
		LFSaw.kr(MouseY.kr(0.2, 8, 'exponential')*pitch), // pos
		env,		// level
		2			// width
	);
	i_said = LocalIn.ar(1);
	LocalOut.ar(outmono);    //This is my voice. I will look for it in the output.
	Out.ar(0, outmix);       //I output it panned
	they_said = i_said;      //We don't have a good feedback bus yet
	loudness = Lag.ar(Mix.new(i_said*i_said), window_time); //autocorrelate.
	A2K.kr(loudness).poll;
	//SendTrig.kr(LFPulse.kr(window_time.reciprocal),0,loudness);
}).send(s);

// register to receive this message
OSCresponder(s.addr,'/tr',{ arg time,responder,msg;
	[time,responder,msg].postln;
}).add;
)

x = Synth(\warp, [\pitch, 1]);
x = Synth(\warp, [\pitch, 1.5]);
x = Synth(\warp, [\pitch, 2]);
x.free;

/*

TODO:
* do loudness calcs at kr (after autocorrelation, at least)


*/