s=~serverboot.(prox:\local, device:\internal);
//TODO: duck compressor input.
//TODO: get external input in
//TODO: LFOs
//TODO: reverb distance thing
//TODO: pitch match?
//TODO: morphing reverb?
//TODO: base detune
//TODO: chaos parameter
//TODO: midi interaction (CCAllocator?)
//TODO: intersting interaction
//TODO: PCA-style decomposition of param values (how to get full range? -inv gaussian map?)
//TODO: Two flocks
(
var state = ~state = (
	\baseCorr: 0.6,
	\baseVal:1,
	\sampLen: 60,
	\baseSampOffset:15,
	\timeStep: 1/4,
	\subTimeStep: 1/4,
	\subLength: 4,
	\meanDb:(-10),
	\dbRange:10,
	\jitter: 1.0,
	\sampPaths: [
		"NS wind chimes 002-denoise-edit.aiff",
		"Lead Vocal.aiff",
		"Stevie Wonder - For Your Love (Acapella).aiff",
		"133_bigbowl2-edit.wav",
		"21646_madjad_Indonesian_Thum_Loop_2_.wav"
	].collect(~zamples +/+ "SupercolliderAuxiliary" +/+ _),
	\clock: TempoClock.new(100.0/60.0),
);
fork {
	state.sampBufs = Buffer.allocConsecutive(
		state.sampPaths.size,
		s, s.sampleRate * state.sampLen, 1);
	s.sync;
	state.sampBufs.do({|buf,ind|
		[\loadin, buf,ind,state.sampPaths[ind]].postln;
		buf.readChannel(state.sampPaths[ind], channels:[0])});
	state.outBus = Bus.new(\audio,0,2,s);
	state.sourceGroup = Group.new(s,'addToHead');
	s.sync;
	state.currBuf = 1;
	state.fxMasterGroup = Group.new(state.sourceGroup,'addAfter');
	state.fxGroups = List.new;
	s.sync;
	4.do({
		state.fxGroups.add(
			Group.new(state.fxMasterGroup, 'addToTail'))
	});
	SynthDef(\snip,
		{|out=0, pitchRatio=1, amp=1.0, attackTime=0.05, releaseTime=1.0, startPos=0, buf=0, pan=0|
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
					rate: pitchRatio,
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
	//basic info
	state[\baseSubPattern] = Pbind(
		\type, \note,
		\instrument, \snip,
		\hasGate, false,
		\buf, state.sampBufs[0],
		\group, state.sourceGroup,
		\db, Pfunc({
			(state.meanDb-state.dbRange
		).rrand(state.meanDb-state.dbRange)}),
	);
	//defaults to mess with. Break out into alternatives?
	state[\superSubPattern1]= Pbind(
		\pitchRatio, 1,
		//see also Pstep for bar-related
		\startPos, Pseries({0.1.linrand(state.sampLen/2)}, {0.0.linrand(1.0)}),
		\pan, Pwhite(-1.0, 1.0, inf),
		\releaseTime, Pwhite(0.1, 3, inf),
	);
	s.sync;
	~masterPattern = Pspawner({|spawner|
		var streams, clatter;
		streams = List.new;
		120.do({|i|
			//logic introduce timing disorder
			var timeOffset=0.0, sampOffset=0.0, subTimeStep=0.0, sampStep=0.0;
			spawner.wait(state[\timeStep]);
			timeOffset = state[\jitter].linrand*state[\timeStep];
			sampOffset = (state[\jitter].rand2+1)*
			  state[\baseSampOffset];
			subTimeStep = (state[\jitter].rand2+1)*
			  state[\subTimeStep];
			//nb this is actually in seconds; should grab clock time maybe?
			sampStep = (state[\jitter].rand2+1)*
			  state[\subTimeStep];
			[i, timeOffset, sampOffset, subTimeStep, sampStep].postln;
			state.sampBufs[state.currBuf];
			streams.add(spawner.par(
				pattern: Pfin(
					state[\subLength].value,
					Pbindf(
						state[\baseSubPattern] <>
						state[\superSubPattern1],
						\buf, state.sampBufs[state.currBuf],
						\startPos, Pseries(
							sampOffset,
							sampStep),
						//\pitchRatio, Prand([1/3,1/2,1,1.5], inf),
					)
				),
				delta: timeOffset;
			));
		});
	}).play(state.clock, quant: #[4,0,0]);
};
)
~state.meanDb=(-50);
~state.currBuf=4;
~state.sampBufs[1].plot;
~state.sampBufs[1].play;
~state.sampBufs[1].query;

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
///To offline pitchtrack:
// First the synthdef
(
	SynthDef(\help_param, { |inbufnum, outbufnum|
		var source, amp, freq, hasfreq;
		source = PlayBuf.ar(1, inbufnum, BufRateScale.kr(inbufnum));
		amp = Amplitude.kr(source);
		BufWr.kr(amp, outbufnum, Phasor.ar(0, BufRateScale.kr(outbufnum) * ControlRate.ir / SampleRate.ir, 0, BufFrames.kr(outbufnum)), 0);
		Out.ar(0, source.dup);
	}).store;
)
// Then we process the files
(
	Score.batchNRT(
	"~/svn/soundsamples/beatboxes/*.wav",	// Input path pattern - note the asterisk wildcard
	"~/dataoutput/parameters",		// Output path
	\help_param,
	outputnameadd: "-parameters",
	outputlengthfunc: {|indur| ((indur) * 44100 / 64).postln}, // Note the way the durations are scaled to the (standard) control rate
	plot:true
	);
)