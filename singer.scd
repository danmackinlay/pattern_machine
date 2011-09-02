(
SynthDef(\sawgrain, { |freq = 440, amp = 0.2, sustain = 1, headroom=400, rq=0.1|
	var	sig, env;
	env = EnvGen.kr(Env.perc(0.01, sustain), doneAction: 2);
	sig = RLPF.ar(Saw.ar(freq, amp), freq + (env * headroom), rq) * env;
	Out.ar(0, sig ! 2);	// sig ! 2 is the same as [sig, sig]
	
}).send(s);

p = Pbind(
		\instrument, \sawgrain,
		\midinote, Pseq([66, 69, 80, 50], inf),
		\dur, Pseq([0.75, 0.25, 0.25, 0.25, 0.5], inf),
		//\legato, Pseq([0.9, 0.3, 0.3, 0.3, 0.3], inf),
		\amp, 0.5, \detune, 1.005
	).play(quant: 1);
)

r = Routine({
	var	delta;
	loop {
		delta = rrand(1, 3) * 0.5;
		Synth(\singrain, [freq: exprand(200, 800), amp: rrand(0.1, 0.5), sustain: delta * 0.8]);
		delta.yield;
	}
});

r.play
)
