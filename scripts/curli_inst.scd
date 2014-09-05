//This should totally be a class; I use it often enough.
//TODO: buffer offset base and range
//TODO: variable barlength (including pspawner counter)
//TODO: switch from Event type Note to Grain, and avoid ahving to think about it
{|state, i|
	state.make({
		// delay/loop action
		~i=i;
		~delscale = state.delscale ? 1.0;
		~amp = state.amp ? 0.5;
		~pan = state.pan ? 0.0;
		~density = state.density ? 1.0; //rate of impacts
		~intensity = state.intensity ? 1.0; //expected polyphony
		~stationarity = state.stationarity ? 1.0;
		~chaos = state.chaos ? 1.0;

		state.voiceStates[i]=(state);
		CmdPeriod.doOnce({ state.voiceStates[i]=nil });
		~sampleDur = state.sampleDur ? 30;
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
			addAction: \addToTail,
			sendGate: false,//persist
			out: ~outbus,
			index: 1,
			wet: 0.2,
			damping: 0.4,
			revtime: 0.8,
			roomsize: 170,
		).play;
		CmdPeriod.doOnce({ state.reverb.free });

		s.sync;
		//NB output not specified! that's why it's playing to master.
		//cannot also be called ~pat or recursive reference manages to happen somehow.
		~basepat = Pbind(*[
			type: \note,
			instrument: \ps_deltaprd_play__1x2,
			group: ~headGroup,
			addAction: \addToTail,
			server: ~server,
			modulate: ~modbus.asMap,
			sendGate: true,
			phasebus: ~loopphasebus,
			bufnum: ~loopbuf,
		]);
		// least troublesome way of reseeding is Pspawner
		~pat = Pspawner({|spawner|
			var bartime=0.0;
			inf.do({|i|
				//Pevent?
				var pat = ~basepat <> Pbind(*[
					attack: PContext(state, \attack, 0.1),
					release: PContext(state, \release, 0.3),
					bartime: Pseg(
						[0,state[\loopBeats]],
						state[\loopBeats], \lin, inf),
					dur: Prand([0,1/2,3/2], inf)*PContext(state, \density, 1.0),
					delta: Prand([1/4,1/2], inf)*(1 +
						 Pfunc({state[\chaos].rand2;})), //or PexpR(Pfunc({state.lambda})),
					deltime: (
						(Prand([0,1/2,3/4,2/3], inf) +
							Pkey(\bartime)
						).wrap(0, state[\loopBeats]) *
						state.beatTime),
					amp: PContext(state, \amp, 0.5),
					pan: PContext(state, \pan, 0.0),
					rate: Prand(state[\trans], inf),
				]);
				//Pindex? or Pfsm?
				spawner.seq(
					Pfindur(
						dur: state[\loopBeats],
						pattern: pat), //.postcs.trace(prefix: \inner),
					//delta: 0,
				);
				//spawner.wait(state[\loopBeats]);
			});
		}).postcs.trace(prefix: \inner);
		/*
		~pat = Pquantize(~pat,
			quant: PContext(state, \quant, 0.5),
			strength: PContext(state, \strength, 1.0),
			debug: true).postcs.trace(prefix: \outer); //.trace;
		*/
		~stream = ~pat.play(clock: ~clock);
		~updateTempo={|self|
			\subupdatetempo.postln;
			self.bpm = self.bpm ? 80.0;
			self.tempo = 60.0/self.bpm;
			self.beatTime = self.tempo.reciprocal;
			self.loopBeats = self.loopBeats ? 8.0;
			self.loopTime = self.beatTime * self.loopBeats;
			self.loopsynth.set(\deltime, self.loopTime);
		};
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