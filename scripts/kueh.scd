s=~serverboot.(prox:\local, device:\internal);
(
fork {
	var state;
	~state = state = ();
	state.sampPath = ~zamples +/+ "hits-tuned/NS wind chimes 002-denoise-edit.wav";
	state.sampLen = 60;
	state.sampBuf = Buffer.alloc(s, s.sampleRate * state.sampLen, 1);
	s.sync;
	state.sampBuf.readChannel(state.sampPath, channels:[0]);
	s.sync;
	state.outBus = Bus.new(\audio,0,2,s);
	state.sourceGroup = Group.new(s,'addToHead');
	s.sync;
	state.fxMasterGroup = Group.new(state.sourceGroup,'addAfter');
	state.fxGroups = List.new;
	s.sync;
	4.do({
		state.fxGroups.add(
			Group.new(state.fxMasterGroup,'addToTail'))
	});
	SynthDef(\snip,
		{|out=0, rate=1, amp=1.0, attackTime=0.05, releaseTime=1.0, startPos=0, buf=0, pan|
			var env,playr;
			env = EnvGen.kr(
				Env.perc(attackTime, releaseTime),
				levelScale: amp,
				gate: 1,
				doneAction: 2
			);
			playr = Pan2.ar(
				PlayBuf.ar(
					numChannels:1,
					bufnum:buf,
					rate: rate,
					trigger: 1,
					startPos: startPos*SampleRate.ir,
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
			FreeVerb2.ar(
				signal[0],
				signal[1],
				mix, room, damp, amp));
	}).add;
	s.sync;
	p = Pbind(
		\type, \note,
		\instrument, \snip,
		\baseRand, Pgauss(length:16),
		\hasGate, false,
		\buf, state.sampBuf,
		\group, state.sourceGroup,
		\db, PSPsi(PSCorr(0.9, Pkey(\baseRand))).linlin(0.0,1.0,-20.0,0.0),
		\pan, PSPsi(PSCorr(0.9, Pkey(\baseRand))).linlin(0.0,1.0,-1.0,1.0),
		\delta, 1/2,
		\offset, 10.8,
	).collect({|in|
		in.asCompileString.postln;
		in;
	}).play;
};
)
~state
~steps1 = Array.series(3001, 0, 1)/3000;
~steps33 = Array.series(3001, -1500, 1)/500;
~steps33.plot;
PSPsi(PSInvPsi(~steps1)).plot;
PSInvPsi(~steps1).plot;
PSPsi(~steps33).plot;
~steps33.collect(PSCorr(0.5, _)).plot;
~steps33.collect(PSCorr(0.9, _)).plot;
PSCorr(0.9, ~steps33, {0.gauss(1)}.dup(~steps33.size)).plot;
~sampBuf.plot;
~sampBuf.play;
~sampBuf.query;

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