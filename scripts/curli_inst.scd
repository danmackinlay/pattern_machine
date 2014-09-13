//This should totally be a class; I use it often enough.
//TODO: buffer offset base and range
//TODO: variable barlength (including pspawner counter)
//TODO: switch from Event type Note to Grain, and avoid having to think about it
//TODO: markovity
{|state, i|
	state.make({
		~i=i;
		state.voiceStates[i]=(state);
		CmdPeriod.doOnce({ state.voiceStates[i]=nil });
		~sampleDur = state.sampleDur ? 30;
		~updateTempo={|self|
			\subupdatetempo.postln;
			self.bpm = self.bpm ? 80.0;
			self.tempo = 60.0/self.bpm;
			self.beatDur = self.tempo.reciprocal;
			self.loopBeats = self.loopBeats ? 8.0;
			self.loopTime = self.beatDur * self.loopBeats;
			self.loopsynth.set(\deltime, self.loopTime);
			self.clock.tempo=self.tempo;
		};
		~loop={|self, loopseed|
			\loop.postln;
			loopseed = loopseed.asBoolean;
			self.loopseed = loopseed;
			self.loopsynth.set(\loop,loopseed);
		};
		state.updateTempo.();
		~loopbuf = Buffer.alloc(~server, ~server.sampleRate * ~sampleDur, 1);
		~modbus = ~parambusallocator.alloc;
		CmdPeriod.doOnce({ state.loopbuf.free });
		~loopphasebus = Bus.control(~server, 1);
		CmdPeriod.doOnce({ state.loopphasebus.free });
		//looks tidier in debug to use groups instead of synths
		~headGroup = Group.head(~instgroup);
		~tailGroup = Group.tail(~instgroup);
		s.sync;

		//delay/loop input
		~loopsynth = (
			instrument: \ps_deltapwr_loop__1x1,
			out: ~inbus,
			bufnum: ~loopbuf,
			wet: 0,
			deltime: ~loopTime,
			phasebus: ~loopphasebus,
			group: ~headGroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).play;
		CmdPeriod.doOnce({ state.loopsynth.free });

		s.sync;

		//channel fx
		~reverb = (
			instrument: \ps_gverb__2x2,
			group: ~tailGroup,
			server: ~server,
			addAction: \addToHead,
			sendGate: false,//persist
			out: ~outbus,
			index: 1,
			wet: 0.2,
			damping: 0.4,
			revtime: 0.8,
			roomsize: 170,
		).play;
		CmdPeriod.doOnce({ state.reverb.free });
		//channel fx
		~jack = (
			instrument: \jack__2,
			group: ~tailGroup,
			server: ~server,
			addAction: \addToTail,
			sendGate: false,//persist
			in: ~outbus,
			out: state.masteroutbus,
		).play;
		CmdPeriod.doOnce({ state.jack.free });

		//cannot also be called ~pat or recursive reference manages to happen somehow.
		~baseevt = (
			type: \note,
			instrument: \ps_deltaprd_play__1x2,
			group: ~headGroup,
			addAction: \addToTail,
			server: ~server,
			modulate: ~modbus.asMap,
			sendGate: true,
			out: ~outbus,
			phasebus: ~loopphasebus,
			bufnum: ~loopbuf,
		);
		// least troublesome way of reseeding is Pspawner
		~pat = Pspawner({|spawner|
			var actualTime=0.0;
			var intendedTime=0.0;
			//For looping
			var intendedFirstBeat = 0.0;
			var candidateIntendedFirstBeat = 0.0;

			inf.do({|i|
				//Pevent?
				var evt, pat;
				var intendedNextTime=0.0;
				var quantizedNextTime=0.0;
				var actualNextTime=0.0;
				var intendedNextDelta;
				var actualNextDelta;
				var overshoot;
				// [state.stationarity, state.density, state.intensity, state.loopBeats,  state.beatDur].postcs;
				// [~stationarity, ~density, ~intensity, ~loopBeats, ~beatDur].postcs;
				//Basic event construction:
				evt = ~baseevt.copy.putAll((
					attack: state.attack ? 1.0,
					release: state.release ? 0.3,
					bartime: intendedTime,
					sustain: 1.0.rand.log.neg/(state.density)*(state.intensity),
					delta: 1.0.rand.log.neg/(state.density),
					deltime: (
						([0,1/2,3/4,2/3].choose + (
							intendedTime*(state.stationarity? 0.0)
						)) % state.loopBeats) * state.beatDur,
					amp: state.amp ? 0.5,
					pan: state.pan ? 0.0,
					rate: 1,
				));
				// "================1================".postln;
				// evt.postcs;
				// "================2================".postln;
				intendedNextDelta = evt.delta;
				// Quantisation logic, adapted from timing.sc
				intendedNextTime = intendedNextDelta + intendedTime;

				// finnicky loop logic
				// TODO: round to 0 if close enough
				overshoot = (intendedNextTime/~loopBeats).floor * ~loopBeats;
				(overshoot>0.0).if({
					//should this be w/ intended time instead? or no difference?
					(state.loopseed).if({
						state.debugSpawn.asBoolean.if({
							["reeeeeeeseeeeeed", state.seed, intendedNextTime, intendedFirstBeat, overshoot + intendedFirstBeat].postln;
						});
						intendedNextTime = overshoot + intendedFirstBeat;
					}, {
						intendedFirstBeat = intendedNextTime - overshoot;
						thisThread.randSeed_(state.seed);
					});
				});

				quantizedNextTime = intendedNextTime.round(state.quant
					).max(actualTime);
				actualNextTime = ((state.strength.neg + 1) * intendedNextTime) +
					(state.strength*quantizedNextTime);
				actualNextDelta = actualNextTime - actualTime;
				evt[\delta] = actualNextDelta;

				state.debugSpawn.asBoolean.if({
					[
						\intendedTime, intendedTime,
						\intendedNextTime, intendedNextTime,
						\intendedNextDelta, intendedNextDelta,
						\quantizedNextTime, quantizedNextTime,
						\actualTime, actualTime,
						\actualNextTime, actualNextTime,
						\actualNextDelta, actualNextDelta,
						\intendedFirstBeat, intendedFirstBeat,
						\overshoot, overshoot
					].postln;
				});

				//actually sequence it.
				pat = Pfin(1, Pevent(evt));
				state.debugSpawn.asBoolean.if({
					//pat = pat.trace(prefix: \deepinner)
				});
				spawner.seq(pat);

				actualTime = actualNextTime - overshoot;
				intendedTime = intendedNextTime - overshoot;
			});
		});
		~stream = ~pat.play(clock: ~clock);
		/*
		~paramUpdater.addUpdater({|val|
			~parambus.set(val.linlin(0.0,1.0,0.0, 2.0));
		});
		~paramUpdater.addUpdater({|val|
			//[\val,val].postln;
			~pan = val.linlin(0.0,1.0,-0.8, 0.8);
		});
		*/
	});
}