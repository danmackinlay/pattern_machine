{|state, i|
	var localvoice;
	localvoice =  state.channel.play(
		Pbind(
			\dur, Pn(1, 10),
			\degree, 1,
		);
		/*
		Pspawner({|spawner|
			inf.do({|i|
				var newSeed, pat, beatTime;
				beatTime = localstate.beatTime;
				//Pindex? or Pfsm?
				pat = Pbind(
					\instrument, \ps_buf_delay_play__1_2,
					\bartime, Pseg(
						[0,localstate[\bardelta]],
						localstate[\bardelta], \lin, inf),
					\bufnum, localstate[\loopbufs][2],
					\phasebus, localstate[\loopphasebuses].subBus(2),
					\dur, Prand([0,1/2,3/2], inf)*Pfunc({localstate[\density]?1}),
					\delta, Prand([0,1/2], inf)*(1+Pfunc({localstate[\chaos].rand2;})),
					\deltime, (
						(Prand([0,1/2,3/4,2/3], inf) +
							Pkey(\bartime)
						).wrap(0, localstate[\bardelta]) *
						beatTime),
					\amp, 1,
					\pan, Pfunc({localstate[\pan]}),
					\rate, Prand(localstate[\trans], inf),
					\sustain, Prand([1,1/2], inf),
					\modulate, localstate[\parambus1].asMap,
				); //.postcs.trace(prefix: \outer)
				localstate[\reseed].if({
					pat = Pseed(localstate[\seed], pat);
				});
				spawner.par(
					pattern: Pfindur(
						dur: localstate[\bardelta],
						pattern: pat), //.postcs.trace(prefix: \inner),
					delta: 0,
				);
				spawner.wait(localstate[\bardelta]);
			});
		}),
		(
			clock: localstate.clock,
			//protoEvent: localstate,
		)
		*/
	);
	/*
	~state=(
	lambda:2,
	quant:1/4,
	strength: 1,
	);
	~patt=Pbind(
	\delta, PexpR(Pfunc({~state.lambda})),
	\degree, Prand([0,3,5,7,10], inf),
	\strength, Pfunc({~state.strength})
	);
	)
	~str=Pquantize(~patt, quant: Pfunc({~state.quant}), debug:true).trace.play;
	~state.quant=1/16;
	~state.lambda=4;
	Pquantize(~patt, quant: 1/4, debug:true).quant;
	~state.lambda=1/4;
	*/
	state.paramUpdaters.add({|val|
		state[\parambus1].set(val.linlin(0.0,1.0,0.0, 2.0));
	});
	state.paramUpdaters.add({|val|
		//[\val,val].postln;
		state[\pan]=val.linlin(0.0,1.0,-0.8, 0.8);
	});
	state;
}