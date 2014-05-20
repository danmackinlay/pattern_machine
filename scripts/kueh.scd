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
// reverb system is not in correct ring arrangment. needs z-crossing
~here = "/Users/dan/src/sc/pattern_machine/scripts";
this.executeFile(~here +/+ "kuehsynths.scd").value(s);

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
			Synth.new(\gverbside__2_2, [
				\outbus, Bus.newFrom(state.sideBus, 0, 2),
				\sidebus, Bus.newFrom(state.sideBus, i*2+2, 2),
				\room, 0.1,
				\damping, 0.4,
				\amp, 1.5, //fades a little
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
	}).play(state.clock, quant: #[4,0,0]);
	this.executeFile(~here +/+ "kuehmidi.scd").value(state);
};
)
~state.sideBus.scope;
s.makeGui;
~state.meanPos=0;
~state.meanPos=0.25;
~state.meanPos=0.875;
~state.meanPos=0.5;
~state.meanPos=1.825;
~state.meanPos=1.5;
~state.posRange=0;
~state.posRange=2;
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
