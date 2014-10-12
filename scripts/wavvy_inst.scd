//TODO: switch from Event type Note to Grain, and avoid having to think about it
//TODO: markovity
//Grain candidates
//Warp1;
//GrainBuf
//BufDur
//TGrains (specified in seconds)
(
		SynthDef.new(\ps_bufrd_phased_grain_mod_echette__1x2, {
			arg out=0,
			bufnum,
			deltime=0.0,
			phasebus,
			rate=1.0,
			posrate=1.0,
			grainsize=0.1,
			windowRandRatio=0.1,
			modulate=0, modlag=0.5, modulateallp=0,
			pan=0, amp=1, gate=1,
			interp=4,
			attack=0.1, release=0.1,
			innerSustainDur=1, sustainDur=1, //Dur to indicate they are measured in seconds, not beats
			allpdeltime=0.1, ringtime=1;

			//Grain candidates
			//Warp1;
			//GrainBuf
			//BufDur
			//TGrains (specified in seconds)

			var sig, innerenv, outerenv, baseTime, readTime, ramp, bufDur;

			bufDur = BufDur.kr(bufnum);
			innerenv = EnvGen.kr(
				Env.linen(
					attackTime: attack,
					sustainTime: (innerSustainDur-attack).max(0),
					releaseTime: release),
				gate: gate,
				levelScale:amp);
			deltime = deltime + ((1-posrate) * Sweep.ar(gate, 1)); //base read pos
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			ramp = Phasor.ar(trig: gate, rate: SampleDur.ir*posrate, end: bufDur); //why is this also a ramp?
			baseTime = Latch.kr(In.kr(phasebus), gate);
			//is the following wrap right for the last sample in the buffer?
			readTime = ((baseTime-deltime)+ramp).wrap(0, bufDur);

			sig = Warp1.ar(
				numChannels: 1,
				bufnum: bufnum,
				pointer: readTime * (bufDur.reciprocal),
				freqScale: rate,
				interp: interp,
				windowSize: grainsize,
				overlaps: 2,
				windowRandRatio: windowRandRatio,
				mul: innerenv
			);

			//OR

			/*sig = BufRd.ar(
				numChannels:1,
				bufnum: bufnum,
				phase: readTime*SampleRate.ir,
				interpolation: interp,
				loop: 1, // Is this actually loop TIME? or interpolation?
			) * innerenv; */
			outerenv = EnvGen.kr(
				Env.linen(
					attackTime: 0,
					sustainTime: sustainDur,
					releaseTime: release
					),
				levelScale: 1,
				doneAction: 2,
			);
			sig = AllpassN.ar(sig,
				delaytime: allpdeltime + Lag2.ar(
					K2A.ar(modulateallp), lagTime: modlag),
				decaytime: ringtime,
				maxdelaytime: 0.5,
				mul: outerenv);
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;

{|state, i|
	state.make({
		~i=i;
		state.voiceStates[i]=(state);
		~sampleDur = state.sampleDur ? 30;
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
			(
				instrument: \ps_bufwr_phased__1x1,
				in: self.inbus,
				bufnum: self.loopbuf,
				phasebus: self.loopphasebus,
				fadetime: 0.05,
				group: self.headGroup,
				addAction: \addToHead,
				dur: dur ? self.loopTime,
			//sendGate: false,//persist
			).trace.play(self[\clock]);
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

		~parentevt = (
			type: \note,
			instrument: \ps_bufrd_phased_grain_mod_echette__1x2,
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
		~seq = PSWavvyseq(state: state, parentEvent: ~parentevt);


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

				sustain = intendedNextDelta * 1.0.rand.log.neg * (~meanoverlap);
				sustain = (((1 - ~strength) * sustain)
					+ (~strength * (sustain.round(~quantum)))
				).clip(~repquantum, 16);
				allPassDelTime = (
					1.0.rand.log.neg*(~meanreptime)
				);
				allPassDelTime = (
					((1 - ~strength) * allPassDelTime)
					+ (~strength * (allPassDelTime.round(~repquantum)))
				).clip(
					0.001.rand+0.001,//rand so we don't ring at set freq because of clipping
					sustain); //no point making it longer than the entire event
				innerSustain = (allPassDelTime * 2).min(sustain);
				//we should still have 20db left at cutoff; is that ok?
				ringTime = (sustain - innerSustain).max(0) * 3;
				//compensate for notes that are mostly allpass
				amp = (innerSustain/sustain).min(1).sqrt * (~meanpower.dbamp);
				//thought- should we be dealing with *effective* sustain times?


				evt[\posrate]=1.0;
				evt[\grainsize]=0.1;
				evt[\windowRandRatio]=0.1;
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

				//actually sequence it.
				pat = Pfin(1, Pevent(evt));
				~debugSpawn.asBoolean.if({
					pat = pat.trace(prefix: \deepinner)
				});
				spawner.seq(pat);
				//wrap around bar end
				actualTime = actualNextTime % (~loopBeats);
				intendedTime = intendedNextTime % (~loopBeats);

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
d=(a:1);
e=(b:2);
e.parent_(d);
e[\b]