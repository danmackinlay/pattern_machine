/*
Apocalypse

TODO: (priority order)
* the param mapping thing
  * MIDI
    * slider velocity?
  * wiimote
* MIDI triggering for:
  * looping
  * loop re-ordering
  * kill all synths (~killall.value;)
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* audio-input-driven effects
* check switching-in-microphone input
* granular choir
* variable delay in front of allpass to make it more interesting
* remap to various RME outputs for hardware mixing (dammit, website down)
* VU meter
* soundfile-length-sensitive sound playing
* interpolated bus inputs for gesture control
* enveloped gestures
* timestretched escalating background accompaniment
* ticking clock sample
* control ableton with SC
* Jack routing into Live?
* Bulk sample loading based on MIR
* stateful algorithm to navigate through with wiimote
*/

//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\builtin);
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
var reverb1, reverb2, reverb3, reverb4;
var uidata, metaparams, params, paramUpdaters, paramWatcher;

~state=\oops;

tempo = 80.0;
beatTime = 60.0/tempo;
clock = TempoClock.default.tempo_(tempo/60.0);

state = (
	clock: clock,
	tempo: tempo,
	beatTime: beatTime,
	paramDirty: false,
);
fork {
	//UI interaction stuff
	metaparams = FloatArray.fill(12,0.5);
	params = FloatArray.fill(32,0.5);
	uidata = (\pitchrollyawaccel: [0.5, 0.5, 0.5, 0.5,].asFloatArray,);
	paramUpdaters = Array.fill(32, nil);
	state.params = params;
	state.metaparams = metaparams;
	state.uidata = uidata;
	state.paramMap = PSRandomMap(inDims:12, outDims:32, phi:1.2);
	state.paramUpdaters = paramUpdaters;

	paramWatcher = Routine({|inval|
		inf.do({|ix|
			state.paramDirty.if({
				state.paramDirty = false;
				[\BBBBBBBBB,state.metaparams].postln;
				state.params = state.paramMap.value(state.metaparams);
			});
			[inval, ix, state.metaparams, state.params].postln;
			inval = 1.0.yield;
		});
	}).play;
	CmdPeriod.doOnce { paramWatcher.free };
	state.paramWatcher = paramWatcher;

	this.executeFile(~pmscripts +/+ "apoca_wii.scd").value(
		uidata,
		{
			(..2).do({|i| metaparams[i] = uidata[\pitchrollyawaccel][i]});
			state.paramDirty=true;
		}
	);
	//this.executeFile(~pmscripts +/+ "apoca_midi.scd").value(state);

	//basic overall mixer setup
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
	mixingboard = MixingBoard("apocalypse", nil,
		echettechannel1,
		echettechannel2,
		bonuschannel1,
		bonuschannel2);
	CmdPeriod.doOnce { mixingboard.free };
	s.sync;
	ingroup = Group.new(s, \addToHead);
	CmdPeriod.doOnce { ingroup.free };
	postgroup = Group.new(s, \addAfter);
	CmdPeriod.doOnce { postgroup.free };

	//channel fx
	reverb3 = bonuschannel1.playfx(\ps_gverb__2_2, [\index, 1]);
	s.sync;

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
		reverb1: reverb1,
		reverb2: reverb2,
		reverb3: reverb3,
		reverb4: reverb4,
		mixingboard: mixingboard,
		postgroup: postgroup,
		sourcebuf: sourcebuf,
		sourcesound: sourcesound,
		control: control,
		subcontrols: subcontrols,
	));
	~state=state;
};

~killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
~killAll = {[~cloud1,~cloud2,~slice1,~slice2].do({|thing| thing.postln;~killList.value(thing)})};
)

~state.sourcesound.set(\bufnum,~sampsetbufdict[\tuneful][3]);
~state.sourcesound.set(\bufnum,~sampsetbufdict[\siren][0]);

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

~killList.value(~cloud1);

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
			\deltime, Prand([0,1/2,2], 32) *~slice1state.beatTime,
			\amp, 1,
		).postcs.trace(prefix:\foo),
	)
);
)
~killList.value(~slice1);

~state.reverb3.set(\wet, 0.8);
~state.reverb3.set(\damping, 0.6);
~state.reverb3.set(\roomsize, 180);
~state.reverb3.set(\revtime, 2);
~state.reverb3.set(\taillevel, 2);
~state.reverb3.set(\earlyreflevel, 2);

~slice1state.loopsynth.set(\wet,1);
~slice1state.loopsynth.set(\wet,0);

~killAll.value;

~state.mixingboard.free;
