//TODO: switch from Event type Note to Grain, and avoid having to think about it
//TODO: markovity
//TODO: think about a less stupid modulation architecture, w/nice LFOs on pos, amp, pan, grainsize, and other LFOs
(
SynthDef.new(\ps_bufgrain_type_1__1x2, {
	arg out=0,
	bufnum,
	timeago=0.0, //how far back from the end we wish to look
	now=0.0,
	sustainDur=1,
	pitchrate=1.0,
	posrate=1.0,
	grainsize=0.1,
	windowRandRatio=0.1,
	pan=0, amp=1, gate=1,
	interp=4,
	attack=0.1, release=0.1;

	//Grain candidates
	//Warp1;
	//GrainBuf
	//BufDur
	//TGrains (specified in seconds)

	var sig,
		env,
		baseTime,
		readTime,
		bufDur;
	bufDur = BufDur.kr(bufnum);
	baseTime = Latch.kr(now, gate);
	//readTime = (baseTime - timeago +
	//	Phasor.ar(trig: gate, rate: SampleDur.ir*posrate, end: bufDur)
	//	).wrap(0, bufDur);
	//Or, since we can do this at control rate
	readTime = Phasor.kr(
		trig: gate,
		rate: ControlDur.ir*posrate,
		start: 0,
		end: bufDur,
		resetPos: (baseTime - timeago).wrap(0, bufDur)
	);
	env = EnvGen.kr(
		Env.linen(
			attackTime: 0,
			sustainTime: sustainDur,
			releaseTime: release
			),
		levelScale: 1,
		doneAction: 2,
	);
	sig = Warp1.ar(
		numChannels: 1,
		bufnum: bufnum,
		pointer: readTime * (bufDur.reciprocal),
		freqScale: pitchrate,
		interp: interp,
		windowSize: grainsize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);

	Out.ar(out, Pan2.ar(sig, pan));
}).add;
)
(
{|state, i|
	state.make({
		var sequencemaker;
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
			instrument: \ps_bufgrain_type_1__1x2,
			group: ~headGroup,
			addAction: \addToTail,
			server: ~server,
			modulate: ~modbus.asMap,
			sendGate: false,
			out: ~outbus,
			now: ~loopphasebus.asMap,
			bufnum: ~loopbuf,
		);
		sequencemaker = {
			20.collect({16.0.rand.round(0.25)}).sort;
		};
		~seq = PSWavvyseq(state: state, parentEvent: ~parentevt);

		~seq.barcallback = {|seq|
			seq.timePoints = sequencemaker.value;
		};
		~seq.notecallback = {|evt, seq|
			var evt;
			evt[\posrate]=0.0;
			evt[\grainsize]=0.1;
			evt[\windowRandRatio]=0.1;
			evt[\sustainDur] = 1 ~beatDur;
			evt[\amp] = amp;
			evt[\pitchrate] = 1;
			evt.postcs;
		};
		~stream = ~seq.play(clock: ~clock);
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
