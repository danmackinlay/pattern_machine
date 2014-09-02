//This should totally be a class; I use it often enough.
//TODO: buffer offset base and range
//TODO: variable barlength (including pspawner counter)

{|state, i|
	state.make({
		// delay/loop action
		~i=i;
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

		~pat = Pbind(
			\instrument, \ps_deltaprd_play__1x2,
			\group, ~headGroup,
			\addAction, \addToTail,
			\server, ~server,
			\bartime, Pseg(
				[0,state[\bardelta]],
				state[\bardelta], \lin, inf),
			\bufnum, ~loopbuf,
			\phasebus, ~loopphasebus,
			\dur, Prand([0,1/2,3/2], inf)*Pfunc({state[\density]?1}),
			\delta, Prand([0,1/2], inf)*(1+Pfunc({state[\chaos].rand2;})), //or PexpR(Pfunc({state.lambda})),
			\deltime, (
				(Prand([0,1/2,3/4,2/3], inf) +
					Pkey(\bartime)
				).wrap(0, state[\bardelta]) *
				state.beatTime),
			\amp, 1,
			\pan, Pfunc({state[\pan]}),
			\rate, Prand(state[\trans], inf),
			\sustain, Prand([1,1/2], inf),
			\modulate, ~modbus.asMap,
		).postcs.trace(prefix: \outer);
		~pat = Pquantize(~pat,
			quant: Pfunc({state.quant}),
			debug: true); //.trace;

		// least troublesome way of reseeding is Pspawner
		~spawnstream = Pspawner({|spawner|
			inf.do({|i|
				var newSeed, pat;
				//Pindex? or Pfsm?
				state[\reseed].if({
					pat = Pseed(state[\seed], ~pat);
				});
				spawner.par(
					pattern: Pfindur(
						dur: state[\bardelta],
						pattern: pat), //.postcs.trace(prefix: \inner),
					delta: 0,
				);
				spawner.wait(state[\bardelta]);
			});
		}).play(clock: ~clock);

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