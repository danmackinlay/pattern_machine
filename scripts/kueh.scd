s=~serverboot.(prox:\local, device:\internal);
(
fork {
	var state;
	~state = state = (\baseCorr: 0.9, \baseVal:1);
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
		\baseRand, PSCorr(
			Pfunc({state.baseCorr}),
			Pfunc({state.baseVal}),
			Pgauss(length:64)
		),
		\hasGate, false,
		\buf, state.sampBuf,
		\group, state.sourceGroup,
		//Now we do fun stuff
		\db, PSPsi(
			PSCorr(0.9, Pkey(\baseRand)),-20.0,0.0
		),
		\pan, PSPsi(PSCorr(0.9, Pkey(\baseRand)),-1.0,1.0),
		\delta, 1/8,
		\offset, 10.8,
	).collect({|in|
		in.asCompileString.postln;
		in;
	}).play;
};
)
~state;

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

