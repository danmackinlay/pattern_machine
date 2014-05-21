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
//TODO: live record?
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
(
var linperturb,state = ~state = (
	\sampLen: 60,
	\timeStep: 1/4,
	\subTimeStep: 1/8,
	\meanSubLength: 2.0,
	\skittishness: 1.0,
	\jitter: 1.0,
	\beatsPerBar: 16,
	\reseedInt: 16,
	\seed: 5,
	\timeShuffleRange: 2.0,
	\meanSampStartPos:15.0,
	\sampStartPosRange:1.0,
	\density: 0.5,
	\meanDb:(-5.0),
	\dbRange:5.0,
	\meanPos: -0.5,
	\posRange: 0.0625,
	\meanDist: 0.0,
	\distRange: 1.0,
	\ratios: [1,1.5,2.0],
	\sampPaths: [
		"NS wind chimes 002-denoise-edit.aiff",
		"Lead Vocal.aiff",
		"Stevie Wonder - For Your Love (Acapella).aiff",
		"133_bigbowl2-edit.wav",
		"21646_madjad_Indonesian_Thum_Loop_2_.wav"
	].collect(~zamples +/+ "SupercolliderAuxiliary" +/+ _),
	\clock: TempoClock.new(100.0/60.0),
);
state.clock.schedAbs(0, {state.clock.beatsPerBar = state.beatsPerBar;});
linperturb = {|center, dev, lo=0, hi=1|
	(dev.asFloat.rand2 + center).max(lo).min(hi);
};
CmdPeriod.doOnce { state.clock.stop };
this.executeFile(~here +/+ "kuehsynths.scd").value(s);

fork {
	this.executeFile(~here +/+ "kuehmidi.scd").value(~state);
	state.sampBufs = Buffer.allocConsecutive(
		state.sampPaths.size,
		s, s.sampleRate * state.sampLen, 1);
	CmdPeriod.doOnce { state.sampBufs.do({|b| b.free;}) };

	s.sync;
	state.sampBufs.do({|buf,ind|
		[\loadin, buf,ind,state.sampPaths[ind]].postln;
		buf.readChannel(state.sampPaths[ind], channels:[0])});
	state.outBus = Bus.new(\audio,0,2,s);
	state.sideBus = Bus.alloc(\audio,s,8);
	state.sourceGroup = Group.new(s,'addToHead');
	CmdPeriod.doOnce { state.outBus.free };
	CmdPeriod.doOnce { state.sideBus.free };
	CmdPeriod.doOnce { state.sourceGroup.free };
	s.sync;
	state.currBuf = 1;
	state.fxMasterGroup = Group.new(state.sourceGroup,'addAfter');
	CmdPeriod.doOnce { state.fxMasterGroup.free };

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
				\outbus, Bus.newFrom(state.sideBus, 6, 2),
				\sidebus, Bus.newFrom(state.sideBus, 4-(i*2), 2),
				\room, 0.1,
				\damping, 0.4,
				\amp, 1.5, //fades a little
				\sidebusAmp, 1.0,
				\index, i,
			], state.fxMasterGroup, 'addToTail')
		);
		s.sync;
	});
	// CmdPeriod.doOnce { state.fxSynths.do({|i| i.free;}) };
	state.jackSynth=Synth.new(\jack__2, [
		\outbus, state.outBus,
		\inbus, Bus.newFrom(state.sideBus, 6, 2)
		], state.fxMasterGroup, 'addToTail');
	// CmdPeriod.doOnce { state.jackSynth.free};
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
		var avgBeatStrength=1.0;
		3000.do({|i|
			var realBeatInBar, beatInBar, perturbedBeatInBar, roundedBeatInBar, beatError, beatStrength;
			var timeOffset=0.0, sampOffset=0.0, subTimeStep=0.0, sampStep=0.0;
			(state.reseedInt>0).if({
				(
					(thisThread.clock.beats % state.reseedInt)==0
				).if {
					thisThread.randSeed = state.seed;
				};
			});
			realBeatInBar = thisThread.clock.beatInBar;
			beatInBar = ( state.timeShuffleRange.sum3rand + realBeatInBar).wrap(0,16);
			//careful = variable gets recycled here:
			roundedBeatInBar = (beatInBar*16).round(1);
			beatStrength = roundedBeatInBar.asInt.gcd(64).log2;
			beatError = roundedBeatInBar-(beatInBar*16);
			//lazy hack to work out mean beat weighting
			avgBeatStrength = (avgBeatStrength* 0.98) + (beatStrength*0.02);
			//(should be ca 1)
			[\time, thisThread.clock.beats, realBeatInBar,beatInBar, roundedBeatInBar, beatStrength, avgBeatStrength].postln;
			// timeOffset = state[\jitter].linrand*state[\timeStep];
			sampOffset = linperturb.(state.meanSampStartPos, state.sampStartPosRange, 5.0, 40.0);
			subTimeStep = linperturb.(state.subTimeStep*state.jitter, state.subTimeStep, 5.0, 40.0);

			subTimeStep = (state[\jitter].rand2+1)*
			  state[\subTimeStep];
			//nb this is actually in seconds; should grab clock time maybe?
			sampStep = (state[\jitter].rand2+1)*
			  state[\subTimeStep];
			//[\subvars, i, timeOffset, sampOffset, subTimeStep, sampStep].postln;
			(state.density * beatStrength /(avgBeatStrength+1)).coin.if({
				spawner.par(
					pattern: Pfin(
						(state.meanSubLength.max(1.0)-1.0) * (1.0.rand.log.neg.min(20)) +1,
						Pbindf(
							state[\baseSubPattern] <>
							state[\superSubPattern1],
							\buf, state.sampBufs[state.currBuf],
							\sampleStartPos, Pseries(
								sampOffset,
								sampStep, inf),
							//\pitchRatio, Prand([1/3,1/2,1,1.5], inf),
							\pos, linperturb.(state.meanPos, state.posRange, -1, 1),
							\dist, linperturb.(state.meanDist, state.distRange, 0, 3),
							\delta, subTimeStep,
						)
					),
					delta: timeOffset
				);
			});
			spawner.wait(state[\timeStep]);
		});
	}).play(state.clock, quant: #[4,0,0.0]);
	this.executeFile(~here +/+ "kuehmidi.scd").value(state);
};
)

~state.sideBus.scope;
s.makeGui;
~state.meanPos=-1.0; //left
~state.meanPos=0.0; //centre
~state.meanPos=1.0; //right
~state.posRange=0.0; //no spread
~state.posRange=2.0; //all spread
~state.meanDist=0.0; //front
~state.meanDist=1.5; //middle
~state.meanDist=3.0; //back
~state.distRange=0.0; //no spread
~state.distRange=2.0; //all spread
~state.meanPos;
~state.meanDb=(-10.0);
~state.density=0.5;
~state.currBuf=1;
~state.jitter=0.1;
~state.jitter=0.05;
~state.jitter=0.0;
~state.subTimeStep=1/128;
~state.subTimeStep=1/3;
~state.meanSampStartPos=15;
~state.meanSampStartPos=0;
~state.sampBufs[1].plot;
~state.sampBufs[1].play;
~state.sampBufs[1].query;
~state.clock.tempo=70/60;
~state.clock.tempo=30/60;
