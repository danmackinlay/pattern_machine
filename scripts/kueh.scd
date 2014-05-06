s=~serverboot.(prox:\local, device:\internal);
(
fork {
	~sampPath= ~zamples +/+ "hits-tuned/NS wind chimes 002-denoise.wav";
	~sampLen = 0;
	~sampBuf = Buffer.alloc(s, s.sampleRate * ~sampLen, 1);
	s.sync;
	~sampBuf.readChannel(~sampPath, channels:[0]);
	s.sync;
	~outBus = Bus.new(\audio,0,2,s);
	~sourceGroup = Group.new(s,'addToHead');
	s.sync;
	~fxgroupGroup1 = Group.new(~sourceGroup,'addToHead');
	s.sync;
	~fxgroupGroup2 = Group.new(~sourceGroup,'addToHead');
	s.sync;
	~fxgroupGroup3 = Group.new(~sourceGroup,'addToHead');
	s.sync;
	~fxgroupGroup4 = Group.new(~sourceGroup,'addToHead');
	SynthDef(\snip,
		{|out=0,rate=1,attackTime=0.05,releaseTime=0.05, startPos=0, bufnum=0, pan|
			var env,playr;
			env = EnvGen.kr(
				Env.perc(attackTime, releaseTime),
				gate: 1,
				doneAction: 2
			);
			playr = Pan2.ar(
				PlayBuf.ar(
					numChannels:1,
					bufnum:bufnum,
					rate: rate,
					startPos: startPos,
				),
				pos: pan,
				level: env
			);
			Out.ar(out, playr);
		},
		[],
	).add;
	SynthDef(\FreeVerb2x2, {
		|outbus, mix=0.25, room=0.15, damp=0.5, amp=1.0|
		var signal;
		signal = In.ar(outbus, 2);
		ReplaceOut.ar(outbus,
			FreeVerb2.ar( // FreeVerb2 - true stereo UGen
				signal[0], // Left channel
				signal[1], // Right Channel
				mix, room, damp, amp));
	}).add;
};
)

// FreeVerb2 - demo synthdef
(
)

// 2ch source
(
a = SynthDef(\src2x2, {
    Out.ar(0,
        Decay.ar(Impulse.ar(1), 0.25, LFCub.ar(1200, 0, 0.1)) ! 2 +
        Pan2.ar(
            Decay.ar(Impulse.ar(1, pi), 0.1, WhiteNoise.ar(0.1)),
            LFNoise1.kr(0.5).range(-1, 1)
        )
    )
}).play
)

///////////////
thisThread.randSeed = 1923;

// create a function that returns a routine

r = { Routine({
    loop({#[1,2,3,4,5].choose.yield })
}) };

Array.fill(7, r.value);

// reset the seed
thisThread.randSeed = 1923;

Array.fill(7, r.value);

////////////

// use the seed to completely reproduce a sound:
(
SynthDef(\help_randomSeed, { arg out=0, freq=440;
    Out.ar(out,
        Line.kr(1, 0, 0.3, doneAction:2) *
        Resonz.ar(
            Dust2.ar([10, 10], 270) + WhiteNoise.ar(4),
        freq, 0.01)
    )
}).send(s);

SynthDef(\help_setRandomSeed, { arg seed=1956, tbus=0.0;
        RandSeed.kr(tbus, seed);
}).send(s);
)

// run a patch
(
x = Synth(\help_setRandomSeed);
r = Routine({
    loop({
        Synth(\help_randomSeed, [\freq, rrand(440, 700)]);
        0.25.wait;
    })
}).play;
)


// make a reset task

(
d = 1250;// seed
t = Task({
    loop({
        x.set(\seed, d, \tbus, 1.0); r.randSeed = d;
        0.1.wait;
        x.set(\tbus, 0.0);
        1.9.wait;
    })
});
)

// sound starts to loop
t.start;

d = 1251; // different loop
d = 1925;


// sound is just like random again, not interested in anything.
t.stop;