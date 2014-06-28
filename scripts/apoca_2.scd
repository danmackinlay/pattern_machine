var localstate, localvox;
localstate = Event.new(n:60, proto:~state).putAll((
	bardelta: 4,
	seed: 1128,
	reseed: true,
	looping: 0,
	parambus1: ~state[\control].subBus(1),
	pan: 0.0,
	chaos: 0,
	trans: [1],
));
~state[\vox2state] = localstate;
localvox = ~state.vox2 = (~state.vox2 ? List.new ).add(
	~state.vox2channel.play(
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
			clock: ~state.clock,
			//protoEvent: localstate,
		)
	)
);
~state.paramUpdaters.add({|val|
	localstate[\parambus1].set(val.linlin(0.0,1.0,0.0, 2.0));
});
~state.paramUpdaters.add({|val|
	//[\val,val].postln;
	localstate[\pan]=val.linlin(0.0,1.0,-0.8, 0.8);
});