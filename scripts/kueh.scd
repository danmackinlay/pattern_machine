s=~serverboot.(prox:\local, device:\internal);
s=~serverboot.(prox:\local, device:\rme);
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
//TODO: choose some control parameters, and map them
//TODO: make pattern more modular by letting it Penvir in a sttings dict. maybe.
//TODO: LIMITER
// Granular delay? Nah not this time, keep it pure.
//see also: "https://github.com/crucialfelix/API/blob/master/JSON.sc"
//"https://github.com/crucialfelix/API" and
//"https://github.com/crucialfelix/supercolliderjs"
// Two posibilities here:
// Explicit melody layers
// forming a melody out of grainclouds by raw copula
// Control mappings for all intersting params

(
var state = ~state = (
	\sampLen: 60,
	\baseSampStartPos:15,
	\timeStep: 1/4,
	\subTimeStep: 1/8,
	\subLength: 4,
	\meanDb:(-5),
	\dbRange:5s,
	\skittishness: 1.0,
	\seed: 4523,
	\reseedInterval:4,
	\jitter: 1.0,
	\meanPos: 1.75,
	\posRange: 0.0625,
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
	SynthDef(\snip,
		{|out=0, pitchRatio=1, amp=1.0, attackTime=0.05, releaseTime=1.0, sampleStartPos=0, buf=0, pan=0|
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
					startPos: sampleStartPos*BufSampleRate.kr(buf),
				),
				pos: pan,
				level: env
			);
			Out.ar(out, playr);
		},
		[],
	).add;
	SynthDef(\snip__8,
		{|out=0, pitchRatio=1, amp=1.0, attackTime=0.05, releaseTime=1.0, sampleStartPos=0, buf=0, pos=0|
			var env,playr;
			env = EnvGen.kr(
				Env.perc(attackTime, releaseTime),
				levelScale: amp,
				gate: 1,
				doneAction: 2
			);
			playr = PanAz.ar(
				numChans:8,
				in: PlayBuf.ar(
					numChannels:1,
					bufnum:buf,
					rate: pitchRatio*BufRateScale.kr(buf),
					trigger: 1,
					startPos: sampleStartPos*BufSampleRate.kr(buf),
				),
				pos: pos,
				level: env
			);
			Out.ar(out, playr);
		},
		[],
	).add;
	//Reverb unit with bonus dry sidemix
	SynthDef(\freeverbside__2_2, {
		|outbus=0, mix=1, room=0.15, damp=0.8, amp=1.0, sidebus=0, sidebusAmp=1, index=0|
		var signal;
		signal = In.ar(outbus, 2);
		signal = FreeVerb2.ar(
			signal[0],
			signal[1],
			mix: mix,
			room: room*(index/100 +1),
			damp: damp,
			amp: amp
		);
		//Freeverb is a little low rent and rings a lot; phase that away
		signal = OnePole.ar(AllpassC.ar(signal,
			maxdelaytime:0.1,
			delaytime: SinOsc.ar(
				index/73+0.02,
				mul:0.005,
				add: 0.021+(index/150)),
			decaytime:0.051),
			coef: 0.5, mul: 1.5);
		signal = signal + (In.ar(sidebus, 2)*sidebusAmp);
		ReplaceOut.ar(outbus,
			signal
			//+SinOsc.ar(freq:220*(1+index), mul: 0.01)
		);
	}).add;
	//Reverb unit with bonus dry sidemix
	SynthDef(\gverbside__2_2, {
		|outbus=0, mix=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel:1.0, earlyreflevel=0.5, sidebus=0, sidebusAmp=1, index=0|
		var signal;
		signal = In.ar(outbus, 2);
		signal = Mix.new(GVerb.ar(
			signal,
			drylevel: 1,
			roomsize: roomsize*(index/100 +1),
			damping: damping,
			taillevel: taillevel,
			revtime: revtime,
			drylevel: 0,
			maxroomsize:400,
			earlyreflevel:earlyreflevel,
			mul: amp,
		));
		signal = signal + (In.ar(sidebus, 2)*sidebusAmp);
		ReplaceOut.ar(outbus,
			signal
			//+SinOsc.ar(freq:220*(1+index), mul: 0.01)
		);
	}).add.dumpUGens;
	SynthDef(\jack__2, {
		|inbus, outbus|
		Out.ar(outbus,In.ar(inbus, 2));
	}).add;
	state.sampBufs = Buffer.allocConsecutive(
		state.sampPaths.size,
		s, s.sampleRate * state.sampLen, 1);
	s.sync;
	state.sampBufs.do({|buf,ind|
		[\loadin, buf,ind,state.sampPaths[ind]].postln;
		buf.readChannel(state.sampPaths[ind], channels:[0])});
	state.outBus = Bus.new(\audio,0,2,s);
	state.sideBus = Bus.alloc(\audio,s,8);
	state.sourceGroup = Group.new(s,'addToHead');

	s.sync;
	state.currBuf = 1;
	state.fxMasterGroup = Group.new(state.sourceGroup,'addAfter');
	state.fxSynths = List.new;
	// state.reverbControls=Bus.control(s,4);
	s.sync;
	// state.reverbRoom=Bus.newFrom(state.reverbControls, 0, 1);
	// state.reverbMix=Bus.newFrom(state.reverbControls, 1, 1);
	// state.reverbDamp=Bus.newFrom(state.reverbControls, 2, 1);
	//3 successive reverbs
	3.do({|i|
		state.fxSynths.add(
			Synth.new(\freeverbside__2_2, [
				\outbus, Bus.newFrom(state.sideBus, 0, 2),
				\sidebus, Bus.newFrom(state.sideBus, i*2+2, 2),
				\mix, 1,
				\room, 0.1,
				\damp, 1.0,
				\amp, 1.1, //fades a little
				\sidebusAmp, 1.0,
				\index, i,
			], state.fxMasterGroup, 'addToTail')
		);
		s.sync;
	});
	// 3.do({|i|
	// 	state.fxSynths.add(
	// 		Synth.new(\jack__2, [
	// 			\outbus, Bus.newFrom(state.sideBus, 0, 2),
	// 			\inbus, Bus.newFrom(state.sideBus, i*2+2, 2),
	// 		], state.fxMasterGroup, 'addToTail')
	// 	);
	// 	s.sync;
	// });
	state.jackSynth=Synth.new(\jack__2, [
		\outbus, state.outBus,
		\inbus, Bus.newFrom(state.sideBus, 0, 2)
		], state.fxMasterGroup, 'addToTail');
	//basic info
	state[\baseSubPattern] = Pbind(
		\type, \note,
		\instrument, \snip__8,
		\hasGate, false,
		\buf, state.sampBufs[0],
		\out, state.sideBus,
		\group, state.sourceGroup,
		\db, Pfunc({
			(state.meanDb-state.dbRange
		).rrand(state.meanDb-state.dbRange)}),
	);
	//defaults to mess with. Break out into alternatives?
	state[\superSubPattern1]= Pbind(
		\pitchRatio, 1,
		//see also Pstep for bar-related
		\releaseTime, Pwhite(0.1, 3, inf),
	);
	s.sync;
	~masterPattern = Pspawner({|spawner|
		var streams, clatter;
		streams = List.new;
		3000.do({|i|
			//logic introduce timing disorder
			var timeOffset=0.0, sampOffset=0.0, subTimeStep=0.0, sampStep=0.0;
			spawner.wait(state[\timeStep]);
			timeOffset = state[\jitter].linrand*state[\timeStep];
			sampOffset = (state[\jitter].rand2+1)*
			  state[\baseSampStartPos];
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
						\sampleStartPos, Pseries(
							sampOffset,
							sampStep, inf),
						//\pitchRatio, Prand([1/3,1/2,1,1.5], inf),
						\pos, state.posRange.asFloat.bilinrand + state.meanPos.post,
						\delta, subTimeStep,
					)
				),
				delta: timeOffset;
			));
		});
	}).collect(_.postln).play(state.clock, quant: #[4,0,0]);
};
)
~state.sideBus.scope;
s.makeGui;
~state.meanPos=0;
~state.meanPos=0.25;
~state.meanPos=0.875;
~state.meanPos=1;
~state.meanPos=1.75;
~state.meanPos=2;
~state.posRange=0;
~state.meanDb=(-50);
~state.currBuf=1;
~state.jitter=0.1;
~state.jitter=0.05;
~state.jitter=0.0;
~state.subTimeStep=1/128;
~state.subTimeStep=1/3;
~state.baseSampStartPos=100000;//doesn't seem to ACUTALLY work
~state.baseSampStartPos=0;//doesn't seem to ACTUALLY work
~state.sampBufs[1].plot;
~state.sampBufs[1].play;
~state.sampBufs[1].query;
~state.clock.tempo=70/60;
~state.clock.tempo=30/60;

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
