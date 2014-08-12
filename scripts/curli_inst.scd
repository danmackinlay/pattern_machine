{|state, i|
	state.make({
		var parambus, inchannel, outchannel, reverb, loopsynth, loopbuf, loopphasebus, stream, pat;

		// delay/loop action action
		loopbuf = Buffer.alloc(s, s.sampleRate * 10.0, 1);
		CmdPeriod.doOnce { loopbuf.free };
		loopphasebus = Bus.control(s, 1);
		CmdPeriod.doOnce { loopphasebus.free };
		parambus = Bus.control(s, 1);
		CmdPeriod.doOnce { parambus.free };
		outchannel = MixerChannel.new("outvox" ++ i.asString, s, 2, 2, outbus: ~masterchannel);
		//is this one necessary?
		CmdPeriod.doOnce { outchannel.free };
		inchannel = MixerChannel.new("invox" ++ i.asString, s, 2, 2, outbus: outchannel);
		//is this one necessary?
		CmdPeriod.doOnce { outchannel.free };
		s.sync;
		~mixingboard.add(inchannel);
		~mixingboard.add(outchannel);

		//delay/loop input
		loopsynth = inchannel.play((
			instrument: \ps_buf_delay_loop__1_1,
			outbus: ~inbus,
			bufnum: loopbuf,
			group: ~ingroup,
			wet: 0,
			deltime: ~beatTime*4,
			phasebus: loopphasebus,
			addAction: \addToTail,
			sendGate: false,//persist
		));
		CmdPeriod.doOnce { loopsynth.free };

		s.sync;

		//channel fx
		reverb = outchannel.playfx(\ps_gverb__2_2, [
				\index, 1,
				\wet, 0.2,
				\damping, 0.4,
				\revtime, 0.8,
				\roomsize, 170,
		]);
		CmdPeriod.doOnce { reverb.free };

		s.sync;

		pat = Pbind(
			\instrument, \ps_buf_delay_play__1_2,
			\bartime, Pseg(
				[0,state[\bardelta]],
				state[\bardelta], \lin, inf),
			\bufnum, loopbuf,
			\phasebus, loopphasebus,
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
			\modulate, parambus.asMap,
		).postcs.trace(prefix: \outer);
		pat = Pquantize(pat,
			quant: Pfunc({state.quant}),
			debug: true); //.trace;
		stream =  state.outchannel.play(pat, (
			clock: state.clock,
		));

		/* //How the Pspawner version works
		Pspawner({|spawner|
			inf.do({|i|
				var newSeed, pat, beatTime;
				beatTime = state.beatTime;
				//Pindex? or Pfsm?
				pat = //BLAH
				state[\reseed].if({
					pat = Pseed(state[\seed], pat);
				});
				spawner.par(
					pattern: Pfindur(
						dur: state[\bardelta],
						pattern: pat), //.postcs.trace(prefix: \inner),
					delta: 0,
				);
				spawner.wait(state[\bardelta]);
			});
		}));
		*/
		~paramUpdater.addUpdater({|val|
			parambus.set(val.linlin(0.0,1.0,0.0, 2.0));
		});
		~paramUpdater.addUpdater({|val|
			//[\val,val].postln;
			state[\pan]=val.linlin(0.0,1.0,-0.8, 0.8);
		});
		~pat = pat;
		~parambus = parambus;
		~loopphasebus = loopphasebus;
		~loopbuf = loopbuf;
		~stream = stream;
		~inchannel = inchannel;
		~outchannel = outchannel;
		~reverb = reverb;
	});
}