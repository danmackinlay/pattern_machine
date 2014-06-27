/*
Apocalypse

TODO: (priority order)
* the param mapping thing
  * slider velocity?
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* audio-input-driven effects
* fix sample path problems
* variable delay in front of allpass to make it more interesting
* timestretched escalating background accompaniment
* VU meter
* soundfile-length-sensitive sound playing
* wiimote!
  * velocity-sensitive gestures
* interpolated bus inputs for gesture control
* enveloped gestures
* ticking clock sample
* Jack routing into Live?
* control ableton with SC
* Bulk sample loading based on MIR
* ipad setup
* upload the previous apocalypse soundtracks
* stateful algorithm to navigate through with wiimote

*/

//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\internal);
~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
this.executeFile(~pmscripts +/+ "apoca_synths.scd");

(
var inbus, outbus;
var ingroup, fxgroup, postgroup;
var loopbuf, loopsynth, loopphasebus;
var sourcebuf, sourcesound, limiter;
var control, subcontrols;
var echettechannel1, echettechannel2, bonuschannel1, bonuschannel2, mixingboard;
var tempo, beatTime, clock;
var state;

tempo=80;
beatTime = 60.0/tempo;
clock = TempoClock.new(tempo/60.0);

state = (
	clock: clock,
	tempo: tempo,
	beatTime: beatTime,
);

fork{
	inbus = Bus.audio(s,1);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	CmdPeriod.doOnce { inbus.free };
	outbus = Bus.new(\audio, 0, 2, s);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	s.sync;
	sourcebuf = ~sampsetbufdict[\tuneful][0];
	echettechannel1 = MixerChannel.new("echette1", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { echettechannel1.free };
	echettechannel2 = MixerChannel.new("echette2", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce {echettechannel2.free };
	bonuschannel1 = MixerChannel.new("bonus1", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { bonuschannel1.free };
	bonuschannel2 = MixerChannel.new("bonus2", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { bonuschannel2.free };
	s.sync;
	mixingboard = MixingBoard("apocalypse", nil, echettechannel1,echettechannel2, bonuschannel1, bonuschannel2);
	CmdPeriod.doOnce { mixingboard.free };
	s.sync;
	ingroup = Group.new(s, \addToHead);
	CmdPeriod.doOnce { ingroup.free };
	postgroup = Group.new(s, \addAfter);
	CmdPeriod.doOnce { postgroup.free };

	//sample-loop action
	loopbuf = Buffer.alloc(s, s.sampleRate * 10.0, 1);
	CmdPeriod.doOnce { loopbuf.free };
	loopphasebus = Bus.control(s, 1);
	CmdPeriod.doOnce { loopphasebus.free };
	s.sync;

	//In case I don't want to sing:
	sourcesound = (
		instrument: \playbuf__1,
		outbus: inbus,
		bufnum: sourcebuf,
		group: ingroup,
		addAction: \addToHead,
		loop:1,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce { sourcesound.free };
	s.sync;

	//delay/loop input
	loopsynth = (
		instrument: \ps_buf_delay_loop__1_1,
		outbus: inbus,
		bufnum: loopbuf,
		group: ingroup,
		wet: 0,
		deltime: beatTime*4,
		phasebus: loopphasebus,
		addAction: \addToTail,
		sendGate: false,//persist
	).play;
	CmdPeriod.doOnce { loopsynth.free };
	s.sync;

	limiter = (
	 	instrument: \limi__2,
	 	group: postgroup,
	 	outbus: outbus,
	).play;
	CmdPeriod.doOnce { limiter.free };
	s.sync;

	control = Bus.control(s, 8);
	CmdPeriod.doOnce { control.free };

	s.sync;
	subcontrols = ~control.numChannels.collect(~control.subBus(_,1););

	state.putAll((
		outbus: outbus,
		inbus: inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		limiter: limiter,
		ingroup: ingroup,
		loopsynth: loopsynth,
		loopbuf: loopbuf,
		loopphasebus: loopphasebus,
		echettechannel1: echettechannel1,
		echettechannel2: echettechannel2,
		bonuschannel1: bonuschannel1,
		bonuschannel2: bonuschannel2,
		fxgroup: fxgroup,
		mixingboard: mixingboard,
		postgroup: postgroup,
		sourcebuf: sourcebuf,
		sourcesound: sourcesound,
		control: control,
		subcontrols: subcontrols,
		params: Array.fill(32,0),
	));
	~state=state;
};
)
~map = PSRandomMap(inDims:2, outDims:5, phi:1.2);
~map.value(0.001,0.9);
~map.value(0.021,0.9);

(
var sourcesound;
this.executeFile(~pmscripts +/+ "apoca_synths.scd");
sourcesound = (
	instrument: \playbuf__1,
	outbus: ~state.inbus,
	bufnum: ~state.sourcebuf,
	group: ~state.echettechannel1.fadergroup,
	addAction: \addBefore,
	loop:1,
	sendGate: false,//won't loop if not told
).play;
~state.sourcesound = sourcesound;
CmdPeriod.doOnce { sourcesound.free };
)
~state.testsound.set(\bufnum,~sampsetbufdict[\tuneful][3]);
~state.testsound.set(\bufnum,~sampsetbufdict[\siren][0]);

(
~cloud1state = Event.new(n:30,proto:~state).putAll(());
~cloud1 = (~cloud1 ? List.new ).add(
	~state.echettechannel1.play(Pbind(
		\instrument, \ps_echette_live__1_2,
		\inbus, ~cloud1state.inbus,
		\ringTime, 8.0,
		\delta, 1/4,
		\deltime, 1.5,
		\amp, 0.5,
	))
);
)

~cloud1.size.do({var thing=~cloud1.pop;thing.stop;thing.free;});

(
~cloud2state = Event.new(n:30,proto:~state).putAll((
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
						\inbus, ~cloud2state.inbus,
						\ringTime, 5.0,
						\delta, Pfin(~cloud2state.eta, Pn(~cloud2state.subdelta, inf)),
						\deltime, ~cloud2state.deltime*~state.beatTime,
						\amp, 1,
					),
					delta: 0,
				);
				spawner.wait(~cloud2state[\delta]);
			});
		})
	)
);
)

~cloud2.size.do({var thing=~cloud2.pop; thing.stop; thing.free;});
~cloud2state.deltime=1.8;
~cloud2state.eta=3;

(
~slice1state = Event.new(n:30,proto:~state).putAll((
	delta: 4,
));
~slice1 = (~slice1 ? List.new ).add(
	~state.bonuschannel1.play(
		// Pspawner({|spawner|
		// 	inf.do({|i|
		// 		var beatTime = ~slice1state.beatTime;
		// 		[\oh, i, beatTime].postln;
		// 		spawner.par(
		// 			pattern: Pbind(
		// 				\instrument, \ps_buf_delay_play__1_2,
		// 				\bufnum, ~slice1state.loopbuf,
		// 				\phasebus, ~slice1state.loopphasebus,
		// 				\dur, 1,
		// 				\deltime, Prand([0,1/2,2], 4) *~slice1state.beatTime,
		// 				\amp, 1,
		// 			).postcs,
		// 			delta: 0,
		// 		);
		// 		spawner.wait(~slice1state[\delta]);
		// 	});
		// })
		Pbind(
			\instrument, \ps_buf_delay_play__1_2,
			\bufnum, ~slice1state.loopbuf,
			\phasebus, ~slice1state.loopphasebus,
			\dur, 1,
			\deltime, Prand([0,1/2,2], 4) *~slice1state.beatTime,
			\amp, 1,
		).postcs.trace(prefix:\foo),
	)
);
)
~slice1state.loopbuf.plot;
~slice1.size.do({var thing=~slice1.pop; thing.stop; thing.free;});
~slice1state.loopsynth.set(\wet,1);

~state.mixingboard.free;
