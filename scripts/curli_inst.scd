//This should totally be a class; I use it often enough.
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
			self.beatDur = self[\clock].tempo.reciprocal;
			self.loopTime = self.beatDur * (self.loopBeats? 4.0);
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
				instrument: \ps_bufwr_phased__1x1,
				in: self.inbus,
				bufnum: self.loopbuf,
				phasebus: self.loopphasebus,
				fadetime: 0.05,
				group: self.headGroup,
				addAction: \addToHead,
				dur: dur ? self.loopTime,
			//sendGate: false,//persist
			))).trace.play(self[\clock]);
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
			instrument: \ps_bufrd_phased_mod_echette__1x2,
			group: ~headGroup,
			addAction: \addToTail,
			server: ~server,
			modulate: ~modbus.asMap,
			sendGate: false,
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
				var innerSustain;
				var sustain;
				var allPassDelTime;
				var ringTime;
				var amp;
				// [state.stationarity, state.density, state.intensity, state.loopBeats,  state.beatDur].postcs;
				// [~stationarity, ~meandensity, ~meanoverlap, ~loopBeats, ~beatDur].postcs;

				//Basic event construction:
				evt = ~baseevt.copy.putAll((
					attack: ~attack,
					decay: ~decay,
					sustainLevel: ~sustainLevel,
					release: ~release,
					amp: ~meanpower.dbamp,
					pan: ~pan,
					rate: 1,
					modulate: 0,
					modlag: 0.5,
					modulateallp: 0,
					innerSustainDur: 1,
					sustainDur: 4,
					allpdeltime: 0.5,
					ringtime: 6,
				));
				// choose quantisation for this iteration:
				~quantum = ~quantumset.unif(~quantumparam);
				intendedNextDelta = (1.0.rand.log.neg/(~meandensity)).clip(0.0, 16);
				//[\intendedNextDelta, intendedNextDelta].postln;
				evt[\delta] = intendedNextDelta;
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
				//
				// Quantisation logic, adapted from timing.sc
				//
				// TODO: round to 0 if close enough
				// TODO: switch back to round instead of roundup, or we don't get notes on the downbeat in the first bar.
				quantizedNextTime = intendedNextTime.round(~quantum);
				weightedNextTime = ((1 - ~strength) * intendedNextTime) +
					(~strength * quantizedNextTime);
				actualNextDelta = (weightedNextTime - actualTime);
				~debugSpawn.asBoolean.if({
					[\CCCC2,\intendedNextDelta,intendedNextDelta,\actualNextDelta,actualNextDelta, \quantum, ~quantum, \strength, ~strength].postln;
				});
				// % ensures that we skip no bars and we don't go backwards; shouldn't be needed except for wacky quantization changes
				(actualNextDelta < 0).if({
					~debugSpawn.asBoolean.if({
						["Whoa shit",
						\actualTime, actualTime,
						\intendedTime, intendedTime,
							\intendedNextDelta,intendedNextDelta,
							\actualNextDelta,actualNextDelta,
							\quantum, ~quantum,
							\strength, ~strength].postln;
					});
					actualNextDelta = actualNextDelta % (~quantum);
				});
				actualNextTime = actualTime + actualNextDelta;
				evt[\delta] = actualNextDelta % (~loopBeats); // % breaks up v. long beats
				//
				// Base delay logic
				//
				// convert time in beats to boring old seconds to work out baseline stationary delay
				nextDelTime = actualNextTime * ~beatDur * (1-~stationarity);
				// next, our delay-beats
				// offset using random list lookup
				//[\deltimeA, nextDelTime, ~loopBeats,  actualNextTime, ~beatDur, ~stationarity].postln;
				nextDelTime = nextDelTime + (
					(~delquantumset.unif(~delquantumvar.asFloat.rand)) *
					(~deljumpset.unif(~deljumpvar.asFloat.rand)) *
					(~delscale) * (~beatDur));
				//[\deltimeB, nextDelTime].postln;
				//don't wrap to sane values; the synth does this anyway
				//nextDelTime = nextDelTime % (~loopBeats*~beatDur);
				//[\deltimeC, nextDelTime].postln;
				evt[\deltime] = nextDelTime;
				//
				// duration/power logic
				//
				// 1. We calculate an intended duration and power
				// 2. We calculate how much of that should be allpass, and what
				// 3. scale amplitude accordingly
				~repquantum = ~quantum * ~repquantumset.unif(
					~repquantumvar.asFloat.rand);
				// ~repeatiness * ~repeatinessvar;

				sustain = intendedNextDelta * 1.0.rand.log.neg * (~meanoverlap);
				sustain = (((1 - ~strength) * sustain)
					+ (~strength * (sustain.round(~quantum)))
				).clip(~repquantum, 16);
				innerSustain = (
					intendedNextDelta * 1.0.rand.log.neg/(~meanoverlap)
				);
				innerSustain = (((1 - ~strength) * innerSustain)
					+ (~strength * (innerSustain.round(~quantum)))
				).clip(~repquantum, 16);
				allPassDelTime = (
					intendedNextDelta * 1.0.rand.log.neg/(~meanoverlap)
				);
				allPassDelTime = (
					((1 - ~strength) * allPassDelTime)
					+ (~strength * (allPassDelTime.round(~repquantum)))
				).clip(0.001.rand+0.001, 16); //rand so we don't ring at set f because of clipping
				//we should still have 20db left at cutoff; is that ok?
				ringTime = (sustain - innerSustain).max(0) * 3;
				//compensate for notes that are mostly allpass
				amp = (innerSustain/sustain).min(1).sqrt * (~meanpower.dbamp);
				//thought- should we be dealing with *effective* sustain times?

				[
					"~meanoverlap", ~meanoverlap,
					\intendedNextDelta, intendedNextDelta,
					\actualNextDelta, actualNextDelta,
					\sustain, sustain,
					\innerSustain, innerSustain,
					\allPassDelTime, allPassDelTime,
					\ringTime, ringTime,
					\amp, amp,
				].postln;

				evt[\sustainDur] = sustain * ~beatDur;
				evt[\innerSustainDur] = innerSustain * ~beatDur;
				evt[\allPassDelTime] = allPassDelTime * ~beatDur;
				evt[\ringTime] = ringTime * ~beatDur;
				evt[\amp] = amp;

				//
				// tuning logic
				//
				evt[\rate] = ~transset.unif(~transvar.asFloat.rand);
				//[\rate, evt[\rate]].postln;

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
		~cleanupList.add({
			state.stream.stop;
		});

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