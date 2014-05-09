s=~serverboot.(prox:\local, device:\internal);
//TODO: duck compressor input.
//TODO: get external input in
//TODO: get RCA to jack
//TODO: bring Karin's book
//TODO: pester Gabriel to get willy fliering
(
fork {
	var state = ~state =(\baseCorr: 0.6, \baseVal:1, \meanDb:(-10), \dbRange:10);
	//state.sampPath = ~zamples +/+ "hits-tuned/NS wind chimes 002-denoise-edit.wav";
	state.sampPath = ~zamples +/+ "acapella/Lead Vocal.wav";
	//state.sampPath = ~zamples +/+ "acapella/Ginuwine - Pony (A Capella).wav";
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
			Group.new(state.fxMasterGroup, 'addToTail'))
	});
	SynthDef(\snip,
		{|out=0, rate=1, amp=1.0, attackTime=0.05, releaseTime=1.0, startPos=0, buf=0, pan=0|
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
	s.sync;
	p = Pbind(
		\type, \note,
		\instrument, \snip,
		\baseRand, Pfuncn({PSCorr(
			state.baseCorr,
			state.baseVal,
		)}, inf),
		\hasGate, false,
		\buf, state.sampBuf,
		\group, state.sourceGroup,
		//Now we do fun stuff
	).collect({|ev|
		ev[\db] = PSPhi(PSCorr(0.0, ev.baseRand), {state.meanDb-state.dbRange}.value, {state.meanDb-state.dbRange}.value);
		ev[\pan] = PSPhi(PSCorr(0.0, ev.baseRand),-1.0,1.0);
		ev[\delta] = {state.baseDelta}.value;
		//ev.test = PSCorr(0, ev.baseRand);
		ev[\timingOffset] = PSPhi(
			PSCorr(0.8, ev.baseRand),
			0.0, ev.baseDelta);
		ev[\startPos] = PSPhi(
			PSCorr(0.8, ev.baseRand),
			0.0, state.sampLen/2);
		ev[\releaseTime] = PSPhi(
			PSCorr(0.8, ev.baseRand),
			0.1, 3);
		ev[\rate] = [1/3,1/2,1,1.5][PSPhi(
			PSCorr(0.8, ev.baseRand),
			0, 3).floor];
		ev;
	}).collect({|in|
		in.postln;
		//state.asString.post;
	}).play;
};
)

~state;
~state[\baseVal]= (-1);
~state[\baseVal]= (1);
~state[\baseCorr]= 0.8;
~state.meanDb=(-8);
~state.baseDelta=1/2;

~sampBuf.plot;
~sampBuf.play;
~sampBuf.query;
PSCorr(0,0.6)
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
}).play;
)
(
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
)