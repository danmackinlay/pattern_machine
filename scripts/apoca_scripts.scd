/*
Apocalypse

TODO: (priority order)
* MIDI/wii triggering for:
  * looping
  * loop re-ordering
  * kill all synths (~killall.value;)
  * triggering karin's gestures
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* markov models with reseedable seed (see MarkovSet)
* audio-input-driven effects
* check switching-in-microphone input
* granular choir
* change random seeds
* epic panning
* meditation bells
* extra chaosifier
* tap sync
* enveloped gestures
* timestretched escalating background accompaniment
* restrict sample looping to first 30 seconds, OR
* soundfile-length-sensitive sound playing OR
* put fade-outs in
* variable delay in front of allpass to make it more interesting
* midi keyboard toggle lights
* VU meter
* ticking clock sample
* control ableton with SC
* Jack routing into Live?
* Bulk sample loading based on MIR
* stateful algorithm to navigate through with wiimote
* instead of explicitly accessing "state" all the time, I should execute all the code inside the Environment, then pop off and pass it around.
* MIDI slider velocity
* remap to various RME outputs for hardware mixing (dammit, website down)
* go to 0-based indexing throughout
*/

//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\builtin);
~state.metaparams;
this.executeFile(~pmscripts +/+ "apoca_setup.scd");

~state.sourcesound.set(\bufnum,~sampsetbufdict[\tuneful][3]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\siren][0]);

(
var cloud1state;
cloud1state = ~cloud1state = Event.new(n:30,proto:~state).putAll(());
~cloud1 = (~cloud1 ? List.new ).add(
	~state.echettechannel1.play(Pbind(
		\instrument, \ps_echette_live__1_2,
		\inbus, cloud1state.inbus,
		\ringTime, 8.0,
		\delta, 1/4,
		\deltime, 1.5,
		\amp, 0.5,
	))
);
)

~killList.value(~cloud1);

(
var cloud2state;
~cloud2state = cloud2state = Event.new(n:30,proto:~state).putAll((
	deltime: 0.4,
	delta: 0.25,
	subdelta: 0.25,
	eta: 0.25,
));
~cloud2 = (~cloud2 ? List.new ).add(
	~state.echettechannel2.play(
		Pspawner({|spawner|
			inf.do({|i|
				var beatTime = ~cloud2state.beatTime;
				[\oh, i, beatTime].postln;
				spawner.par(
					pattern: Pbind(
						\instrument, \ps_echette_live__1_2,
						\inbus, cloud2state.inbus,
						\ringTime, 5.0,
						\delta, Pfin(cloud2state.eta, Pn(cloud2state.subdelta, inf)),
						\deltime, cloud2state.deltime*~state.beatTime,
						\amp, 1,
					),
					delta: 0,
				);
				spawner.wait(cloud2state[\delta]);
			});
		}),
		(
			clock: ~state.clock,
			//protoEvent: ~cloud2state,
		)
	)
);
)

~killList.value(~cloud2);

~cloud2state.deltime=1.8;

(
var localstate;
~state.vox3state = localstate = Event.new(n:60, proto:~state).putAll((
	bardelta: 4,
	seed: 1128,
	reseed: true,
	looping: 0,
));
~state.vox3 = (~state.vox3 ? List.new ).add(
	~state.bonuschannel1.play(
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
					\dur, Prand([0,1/2,3/2], inf),
					\delta, Prand([0,1/2], inf),
					\deltime, (
						(Prand([0,1/2,3/4,2/3], inf) +
							Pkey(\bartime)
						).wrap(0, localstate[\bardelta]) *
						beatTime),
					\amp, 1,
					\pan, Pwhite(-1,1),
					\rate, Prand([0.5,1,2], inf),
					\sustain, Prand([1,1/2], inf),
					\modulate, localstate[\control].subBus(0).asMap,
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
		})
	)
);
)
~killList.value(~state.vox3);
~state.vox3state.bardelta;
~state.vox3state[\control].setPairs(0,2);
~state.vox3state[\control].setPairs(0,8);
~state.vox3state[\reseed]=true;
~state.vox3state[\reseed]=false;
~state.vox3state.loopsynths[2].set(\wet,1);
~state.vox3state.loopsynths[2].set(\wet,0);

~killAll.value;

~state.mixingboard.free;


~sampsetpaths;
~sampsetbufdict;
~sampsetbufarray;