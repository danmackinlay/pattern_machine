{|state, i|
	var localvoice, pat;
	pat = Pbind(
		\instrument, \ps_buf_delay_play__1_2,
		\bartime, Pseg(
			[0,state[\bardelta]],
			state[\bardelta], \lin, inf),
		\bufnum, state[\loopbuf],
		\phasebus, state[\phasebus],
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
		\modulate, state[\parambus1].asMap,
	); //.postcs.trace(prefix: \outer);
	pat = Pquantize(pat,
		quant: Pfunc({state.quant}),
		debug: true); //.trace;
	localvoice =  state.channel.play(pat,(
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
	state.paramUpdaters.add({|val|
		state[\parambus1].set(val.linlin(0.0,1.0,0.0, 2.0));
	});
	state.paramUpdaters.add({|val|
		//[\val,val].postln;
		state[\pan]=val.linlin(0.0,1.0,-0.8, 0.8);
	});
	localvoice;
}