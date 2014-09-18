//This should totally be a class; I use it often enough.
//TODO: buffer offset base and range
//TODO: variable barlength (including pspawner counter)
//TODO: switch from Event type Note to Grain, and avoid having to think about it
//TODO: markovity
{|state, i|
	state.make({
		~i=i;
		state.voiceStates[i]=(state);
		~sampleDur = state.sampleDur ? 30;
		~updateTempo={|self|
			\subupdatetempo.postln;
			self.bpm = self.bpm ? 80.0;
			self.tempo = 60.0/self.bpm;
			self.quantum = self.quantum ? (1/4);
			self.beatDur = self.tempo.reciprocal;
			self.loopBeats = self.loopBeats ? 8.0;
			self.loopTime = self.beatDur * self.loopBeats;
			self.clock.tempo=self.tempo;
		};
		~loopin={|self, loopseed|
			[\loop, loopseed].postln;
			loopseed = loopseed.asBoolean;
			self.loopseed = loopseed;
			self.loopseed;
		};
		~cleanup={|self|
			var nextitem, ct = self.cleanupList.size;
			//[\precleaning, ct].postln;
			{self.cleanupList.isEmpty.not}.while({
				nextitem = self.cleanupList.pop;
				ct = ct-1;
				{
					//[\cleaning, self.i, ct].postln;
					nextitem.value;
				}.try(_.postcs);
			});
		};
		~cleanupList = List.new;
		CmdPeriod.doOnce({ state.cleanup();});
		//can't do this one until the list exists; has to be first if at all
		//~cleanupList.add({ state.voiceStates[i]=nil });

		state.updateTempo();
		~loopbuf = Buffer.alloc(~server, ~server.sampleRate * ~sampleDur, 1);
		~cleanupList.add({ state.loopbuf.free });
		~modbus = Bus.control(~server,1);
		~cleanupList.add({ state.modbus.free });
		~loopphasebus = Bus.control(~server, 1);
		~cleanupList.add({ state.loopphasebus.free });
		//looks tidier in debug to use groups instead of synths
		~headGroup = Group.head(~instgroup);
		~tailGroup = Group.tail(~instgroup);
		s.sync;

		//delay input
		~rec = {|self, dur|
			//[\rec, \self, self].postcs;
			//[\rec, \dur, dur].postcs;
			Pfin(1, Pevent((
				instrument: \ps_bufwr_phased_1x1,
				in: self.inbus,
				bufnum: self.loopbuf,
				phasebus: self.loopphasebus,
				fadetime: 0.05,
				group: self.headGroup,
				addAction: \addToHead,
				dur: dur ? self.loopTime,
			//sendGate: false,//persist
			))).trace.play(~clock);
		};

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
		~cleanupList.add({ state.reverb.free });
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
		~cleanupList.add({ state.jack.free });

		//cannot also be called ~pat or recursive reference manages to happen somehow.
		~baseevt = (
			type: \note,
			instrument: \ps_bufrd_phased_mod__1x2,
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
			var weightedNextTime;
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
				var nextDelTime=0.0;
				var overshoot;
				// [state.stationarity, state.density, state.intensity, state.loopBeats,  state.beatDur].postcs;
				// [~stationarity, ~density, ~intensity, ~loopBeats, ~beatDur].postcs;
				//Basic event construction:
				evt = ~baseevt.copy.putAll((
					attack: ~attack ? 1.0,
					release: ~release ? 0.3,
					amp: ~amp,
					pan: ~pan,
					rate: 1,
				));
				intendedNextDelta = (1.0.rand.log.neg/(~density)).min(30);
				evt[\delta] = intendedNextDelta;
				evt[\sustain] = (
					intendedNextDelta * 1.0.rand.log.neg/(~intensity)
				).min(30);

				intendedNextTime = intendedNextDelta + intendedTime;
				~debugSpawn.asBoolean.if({
					[
						\BBBB,
						\quantum, ~quantum,
						\loopBeats, ~loopBeats,
						\loopseed, ~loopseed,
						\intendedTime, intendedTime,
						\intendedNextTime, intendedNextTime,
						\intendedNextDelta, intendedNextDelta,
						\intendedFirstBeat, intendedFirstBeat,
					].postln;
				});
				// finnicky loop logic
				overshoot = (intendedNextTime/~loopBeats).floor * ~loopBeats;
				(overshoot>0.0).if({
					//should this be w/ intended time instead? or no difference?
					(~loopseed).if({
						~debugSpawn.asBoolean.if({
							["reeeeeeeseeeeeed1",
								\intendedNextTime,
								intendedNextTime,
								\intendedFirstBeat,
								intendedFirstBeat,
								\intendedNextTime2,
								overshoot + intendedFirstBeat].postln;
						});
						intendedNextTime = overshoot + intendedFirstBeat;
						intendedNextDelta = intendedNextTime - intendedTime;
						~debugSpawn.asBoolean.if({
							["reeeeeeeseeeeeed2",
								\intendedNextTime,
								intendedNextTime,
								\intendedNextDelta,
								intendedNextDelta].postln;
						});
						thisThread.randSeed_(~seed);
					}, {
						intendedFirstBeat = intendedNextTime % ~loopBeats;
						~debugSpawn.asBoolean.if({
							["nooooreeeeeeeseeeeeed",
								\intendedNextTime,
								intendedNextTime,
								\loopBeats,
								~loopBeats,
								\intendedFirstBeat,
								intendedFirstBeat].postln;
						});

					});
				});
				~debugSpawn.asBoolean.if({
					[
						\CCCC,
						\quantum, ~quantum,
						\loopBeats, ~loopBeats,
						\intendedTime, intendedTime,
						\intendedNextTime, intendedNextTime,
						\intendedNextDelta, intendedNextDelta,
						\overshoot, overshoot,
					].postln;
				});
				// Quantisation logic, adapted from timing.sc
				// TODO: round to 0 if close enough
				// TODO: switch back to round instead of roundup, or we dont' get notes on the downbeat in the first bar.
				quantizedNextTime = intendedNextTime.roundUp(~quantum);
				weightedNextTime = ((1 - ~strength) * intendedNextTime) +
					(~strength * quantizedNextTime);
				actualNextDelta = (weightedNextTime - actualTime);
				~debugSpawn.asBoolean.if({
					[\CCCC2,\actualNextDelta,actualNextDelta, \quantum, ~quantum, \strength, ~strength].postln;});
				// % ensures that we skip no bars and we don't go backwards; shouldn't be needed
				(actualNextDelta < 0).if({actualNextDelta = actualNextDelta % (~quantum)});
				actualNextTime = actualTime + actualNextDelta;
				evt[\delta] = actualNextDelta % (~loopBeats); //break up v. long beats
				//estimate a fruitful delay time
				nextDelTime = actualNextTime*(~stationarity);
				[\deltimeA, nextDelTime].postln;
				//optional offset
				nextDelTime = nextDelTime + (((~beatoffsets ? [0,1,2,3]).choose) * (~beatDur)*(~delscale ? 1));
				[\deltimeB, nextDelTime].postln;
				//don't wrap to sane values; the synth does this anyway
				//nextDelTime = nextDelTime % (~loopBeats*~beatDur);
				//[\deltimeC, nextDelTime].postln;
				evt[\deltime] = nextDelTime;

				~debugSpawn.asBoolean.if({
					[
						\DDDD,
						\actualNextTime,actualNextTime,
						\evtdelta,evt[\delta],
						\quantum, ~quantum,
						\loopBeats, ~loopBeats,
						\intendedTime, intendedTime,
						\intendedNextTime, intendedNextTime,
						\intendedNextDelta, intendedNextDelta,
						\quantizedNextTime, quantizedNextTime,
						\weightedNextTime, weightedNextTime,
						\actualTime, actualTime,
						\actualNextTime, actualNextTime,
						\actualNextDelta, actualNextDelta,
						\intendedFirstBeat, intendedFirstBeat,
						\deltime, nextDelTime,
					].postln;
				});

				//actually sequence it.
				pat = Pfin(1, Pevent(evt));
				~debugSpawn.asBoolean.if({
					pat = pat.trace(prefix: \deepinner)
				});
				spawner.seq(pat);
				//wrap around bar end
				actualTime = actualNextTime % (~loopBeats);
				intendedTime = intendedNextTime % (~loopBeats);

				~debugSpawn.asBoolean.if({
					[
						\EEEE,
						\quantum, ~quantum,
						\loopBeats, ~loopBeats,
						\intendedTime, intendedTime,
						\intendedNextTime, intendedNextTime,
						\actualTime, actualTime,
						\actualNextTime, actualNextTime,
					].postln;
				});

			});
		});
		~stream = ~pat.play(clock: ~clock);
		~cleanupList.add({ state.stream.free });

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