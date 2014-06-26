/*
Apocalypse

TODO: (priority order)
* the param mapping thing
  * slider velocity?
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* sample-and hold delay sequence
* audio-input-driven effects
* fix sample path problems
* variable delay in front of allpass to make it more interesting
* timestretched escalating background accompaniment
* .parentEvent
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

//s=~serverboot.(prox:\local, device:\rme);
s=~serverboot.(prox:\local, device:\internal);
~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
this.executeFile(~pmscripts +/+ "apoca_synths.scd");

~sampsetpaths;
~sampsetbufdict;
~sampsetbufarray;

MIDIClient.init;
//MIDIClient.destinations;
~midiout = MIDIOut.newByName("IAC-Driver", "Bus 1");
~miditeacher = this.executeFile(~pmscripts +/+ "miditeach.scd").value(
	 ~midiout,
	[[5,0], [5,1], [5,2], [5,3], [5,4]]
);

(
var inbus, outbus;
var ingroup, mixergroup, voxgroup, fxgroup, postgroup;
var testbuf, testsound, limiter;
var control, subcontrols;
var echettechannel1, echettechannel2, bonuschannel1, bonuschannel2, mixingboard;
var tempo=120, clock;
var state;

clock = TempoClock.new(tempo/60.0);
state = (
	clock: clock,
	tempo: tempo,
);

fork{
	inbus = Bus.audio(s,1);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	CmdPeriod.doOnce { inbus.free };
	outbus = Bus.new(\audio, 0, 2, s);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	s.sync;
	testbuf = ~sampsetbufdict[\tunefulpaths][0];
	echettechannel1 = MixerChannel.new("echette1", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { echettechannel1.free };
	echettechannel2 = MixerChannel.new("echette2", s, 2,2, outbus:outbus);
	CmdPeriod.doOnce { echettechannel2.free };
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

	//In case I don't want to sing
	/*testsound = (
		instrument: \playbuf__1,
		outbus: inbus,
		bufnum: testbuf,
		group: echettechannel1.fadergroup,
		addAction: \addBefore,
	loop:1,
		sendGate: false,//won't loop if not told
	).play;
	CmdPeriod.doOnce { testsound.free };
	s.sync;*/

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
		inbus: inbus,
		limiter: limiter,
		ingroup: ingroup,
		testbuf: testbuf,
		echettechannel1: echettechannel1,
		echettechannel2: echettechannel2,
		bonuschannel1: bonuschannel1,
		bonuschannel2: bonuschannel2,
		fxgroup: fxgroup,
		mixingboard: mixingboard,
		postgroup: postgroup,
		testsound: testsound,
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
var testsound;
this.executeFile(~pmscripts +/+ "apoca_synths.scd");
testsound = (
	instrument: \playbuf__1,
	outbus: ~state.inbus,
	bufnum: ~sampsetbufdict[\tunefulpaths][0],
	group: ~state.echettechannel1.fadergroup,
	addAction: \addBefore,
	loop:1,
	sendGate: false,//won't loop if not told
).play;
~state.testsound = testsound;
CmdPeriod.doOnce { testsound.free };
)
~state.testsound.set(\bufnum,~sampsetbufdict[\tunefulpaths][3]);
~state.testsound.set(\bufnum,~sampsetbufdict[\sirenpaths][0]);

(
~cloud1 = (~cloud1 ? List.new ).add(
	~state.echettechannel1.play(Pbind(
		\instrument, \echette_live__1_2,
		\inbus, ~state.inbus, //or Bus.newFrom(s.inputBus,0,1) for external
		\ringTime, 8.0,
		\delta, 1/4,
		\deltime, 1.5,
		\amp, 0.5,
	))
);
)

~cloud1.size.do({var thing=~cloud1.pop;thing.stop;thing.free;});
)

(
~cloud2state = (
	deltime: 0.4,
	delta: 0.25,
	subdelta: 0.25,
	eta: 0.25,
);
~cloud2=(~cloud2 ? List.new ).add(
	~state.echettechannel2.play(
		Pspawner({|spawner|
			inf.do({|i|
				[\oh, i].postln;
				spawner.par(
					pattern: Pbind(
						\instrument, \echette_live__1_2,
						\inbus, ~state.inbus, //or Bus.newFrom(s.inputBus,0,1) for external
						\ringTime, 5.0,
						\delta, Pfin(~cloud2state.eta, Pn(~cloud2state.subdelta, inf)),
						\deltime, ~cloud2state.deltime,
						\amp, 2,
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

~state.mixingboard.free;
