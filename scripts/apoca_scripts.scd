/*
Apocalypse

TODO: (priority order)
* the param mapping thing
  * MIDI
* MIDI triggering for:
  * looping
  * loop re-ordering
  * kill all synths (~killall.value;)
  * triggering karin's gestures
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* audio-input-driven effects
* check switching-in-microphone input
* granular choir
* epic panning
* restrict sample looping to first 30 seconds, OR
* soundfile-length-sensitive sound playing
* variable delay in front of allpass to make it more interesting
* VU meter
* enveloped gestures
* timestretched escalating background accompaniment
* ticking clock sample
* control ableton with SC
* Jack routing into Live?
* Bulk sample loading based on MIR
* stateful algorithm to navigate through with wiimote
* markov models with reseedable seed (see MarkovSet)
* bar-pos-aware pattern
* instead of explicitly accessing "state" all the time, I should execute all the code inside the Environment, then pop off and pass it around.
* MIDI slider velocity
* remap to various RME outputs for hardware mixing (dammit, website down)
*/

//Server.default=s=~serverboot.(prox:\local, device:\rme);
Server.default=s=~serverboot.(prox:\local, device:\builtin);

(
var inbus, outbus;
var ingroup, fxgroup, postgroup;
var loopbufs, loopsynths, loopphasebuses;
var sourcebuf, sourcesound, limiter;
var control;
var echettechannel1, echettechannel2, bonuschannel1, bonuschannel2, mixingboard;
var tempo, beatTime, clock;
var state;
var reverb1, reverb2, reverb3, reverb4;
var pitchrollyawaccel, metaparams, params, paramUpdaters, paramWatcher;
var mididefs;

~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
this.executeFile(~pmscripts +/+ "apoca_synths.scd");

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
	pitchrollyawaccel = FloatArray.fill(4,0.5);
	paramUpdaters = Array.fill(32, nil);
	mididefs = List.new;
	state.params = params;
	state.metaparams = metaparams;
	state.pitchrollyawaccel = pitchrollyawaccel;
	state.paramMap = PSRandomMap(inDims:12, outDims:32, phi:1.2);
	state.paramUpdaters = paramUpdaters;
	state.mididefs = mididefs;

	paramWatcher = Routine({|newinval|
		var lastposttime=0.0, delta=0.0;
		inf.do({|ix|
			state.paramDirty.if({
				state.paramDirty = false;
				(delta>5.0).if({
					[\wii_updating,state.metaparams, newinval, delta].postln;
					lastposttime = newinval;
				});
				state.params = state.paramMap.value(state.metaparams);
				state.params.do({|val, i|
					state.paramUpdaters[i].value(val);
				});
			});
			newinval = 0.02.yield;
			delta = newinval-lastposttime;
		});
	}).play;
	CmdPeriod.doOnce { paramWatcher.free };
	state.paramWatcher = paramWatcher;

	this.executeFile(~pmscripts +/+ "apoca_wii.scd").value(state);
	//to disable:
	//OSCdef(\wii).free;
	CmdPeriod.doOnce { OSCdef(\wii).free };

	this.executeFile(~pmscripts +/+ "apoca_midi.scd").value(state).do(state.mididefs.add(_));
	CmdPeriod.doOnce { mididefs.do(MIDIdef(_).free) };


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
	mixingboard = MixingBoard.new("apocalypse", nil,
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
	reverb1 = echettechannel1.playfx(\ps_gverb__2_2, [
		\index, 1,
		\wet, 0.2,
		\damping, 0.4,
		\revtime, 0.8,
		\roomsize, 170,
	]);
	reverb2 = echettechannel2.playfx(\ps_gverb__2_2, [
		\index, 2,
		\wet, 0.7,
		\damping, 0.3,
		\revtime, 2.0,
		\roomsize, 190,
	]);
	reverb3 = bonuschannel1.playfx(\ps_gverb__2_2, [
		\index, 3,
		\wet, 0.3,
		\damping, 0.8,
		\revtime, 1.0,
		\roomsize, 210,
	]);
	reverb4 = bonuschannel2.playfx(\ps_gverb__2_2, [
		\index, 4,
		\wet, 0.8,
		\damping, 0.3,
		\revtime, 4,
		\roomsize, 180,
	]);
	s.sync;

	//sample-loop action
	loopbufs = Buffer.allocConsecutive(4, s, s.sampleRate * 10.0, 1);
	CmdPeriod.doOnce { loopbufs.do(_.free) };
	loopphasebuses = Bus.control(s, 4);
	CmdPeriod.doOnce { loopphasebuses.free };
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
	loopsynths = 4.collect({|i|(
		instrument: \ps_buf_delay_loop__1_1,
		outbus: inbus,
		bufnum: loopbufs[i],
		group: ingroup,
		wet: 0,
		deltime: beatTime*4,
		phasebus: loopphasebuses.subBus(i),
		addAction: \addToTail,
		sendGate: false,//persist
	).play;});
	CmdPeriod.doOnce { loopsynths.do(_.free) };
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

	state.putAll((
		outbus: outbus,
		inbus: inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		limiter: limiter,
		ingroup: ingroup,
		loopsynths: loopsynths,
		loopbufs: loopbufs,
		loopphasebuses: loopphasebuses,
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
	));
	~state=state;
};

~killList = {|thelist| thelist.size.do({var thing=thelist.pop; thing.stop; thing.free;})};
~killAll = {[~cloud1,~cloud2,~slice1,~slice2].do({|thing| thing.postln;~killList.value(thing)})};
)

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
~slice1state = localstate = Event.new(n:60, proto:~state).putAll((
	bardelta: 4,
	seed: 1128,
	reseed: true,
));
~slice1 = (~slice1 ? List.new ).add(
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
~killList.value(~slice1);
~slice1state.bardelta;
~slice1state[\control].setPairs(0,2);
~slice1state[\control].setPairs(0,8);
~slice1state[\reseed]=true;
~slice1state[\reseed]=false;
~slice1state.loopsynth.set(\wet,1);
~slice1state.loopsynth.set(\wet,0);

~killAll.value;

~state.mixingboard.free;

~state.metaparams[2] = 0.01;
~state.metaparams[3] = 0.99;
~state.paramDirty = true;
~state.params;
~state.sourcebuf;

~sampsetpaths;
~sampsetbufdict;
~sampsetbufarray;