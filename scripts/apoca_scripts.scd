/*
Apocalypse

TODO:
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* Bulk sample loading based on MIR
* the param mapping thing
* wiimote!
* ipad setup
* control ableton with SC
* feedback effects?
* CMD-Period crash-robustness
* stateful algorithm to navigate through with wiimote
* Jack routing into Live?
* audio-input-driven effects
* Snipple-style decaying voice sample grains
* garbage collection: CmdPeriod.doOnce { state.outBus.free };

*/
////////
s=~serverboot.(prox:\local, device:\internal);
~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
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
var testbuf, testsound;
var state;
var echettechannel1, mixingboard;

state = ();
fork{
	inbus = Bus.audio(s,1);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	outbus = Bus.new(\audio, 0, 2, s);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	s.sync;
	testbuf = ~sampsetbufdict[\tunefulpaths][0];
	echettechannel1 = MixerChannel.new("echette1", s, 2,2, outbus:outbus);
	s.sync;
	mixingboard = MixingBoard("apocalypse", nil, echettechannel1);
	s.sync;
	ingroup = Group.new(s, \addToHead);
	postgroup = Group.new(s, \addToTail);


	//In case I don't want to sing
	/*state.testsound = (
		instrument: \playbuf__1,
		outbus: inbus,
		bufnum: testbuf,
		group: echettechannel1.fadergroup,
		addAction: \addBefore,
	loop:1,
		sendGate: false,//won't loop if not told
	).play;
	s.sync;*/
	state[\limiter] = (
	 	instrument: \limi__2,
	 	group: postgroup,
	 	outbus: outbus,
	).play;
	s.sync;

	state.putAll((
		outbus: outbus,
		inbus: inbus,
		ingroup: ingroup,
		testbuf: testbuf,
		echettechannel1: echettechannel1,
		fxgroup: fxgroup,
		mixingboard: mixingboard,
		postgroup: postgroup,
	));

	// ~control = Bus.control(s, 4);
	// s.sync;
	// ~subcontrols = ~control.numChannels.collect(~control.subBus(_,1););
	~state=state;
};
)
~map = PSRandomMap(inDims:2, outDims:5, phi:1.2);
~map.value(0.001,0.9);
~map.value(0.021,0.9);
(
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");

~cloud1 = ~state.echettechannel1.play(Pbind(
	\instrument, \echette_live__1_2,
	\inbus, ~state.inbus, //or Bus.newFrom(s.inputBus,0,1) for external
	\ringTime, 5.0,
	\delta, 1/4,
	\deltime, 0.1,
	\amp, 2,
));
~state.mixingboard.free;
~cloud1=~state.echettechannel1.play(\echette_live__1_2, [\ringtime, 4,\pan, -0.3, \deltime, 0.5]);
)
~state.echettechannel1.fadergroup;
~state.testsound = (
	instrument: \playbuf__1,
	outbus: ~state.inbus,
	bufnum: ~sampsetbufdict[\tunefulpaths][0],
	group: ~state.echettechannel1.fadergroup,
	addAction: \addBefore,
	loop:1,
	sendGate: false,//won't loop if not told
).play;