/*
Apocalypse

Ideas:
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* Bulk sample loading based on MIR
* the param mapping thing
* wiimote!
* feedme script too?
* ipad setup
* control ableton with SC
* feedback effects?
* CMD-Period crash-robustness
* stateful algorithm to navigate through with wiimote
* Jack routing into Live?
* audio-input-driven effects
* process all sample library into mono aiff
* Snipple-style decaying voice sample grains
* garbage collection 	CmdPeriod.doOnce { state.outBus.free };

*/
////////
s=~serverboot.(prox:\local, device:\internal);
~apocasamp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
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
~map = PSRandomMap(inDims:2, outDims:5, phi:1.2);
~map.value(0.001,0.9);
~map.value(0.021,0.9);
(
var inbus, outbus;
var ingroup, mixergroup, voxgroup, fxgroup, postgroup;
var testsample, testbuf, testsound;
var state;
var echettechannel1, mixingboard;

state = ();

fork{
	inbus = Bus.audio(s,1);
	outbus = Bus.new(\audio, 0, 2, s);
	//testbuf = Buffer.read(s, testsample);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	this.executeFile(~pmscripts +/+ "apoca_samples.scd").value(~apocasamp);
	s.sync;
	echettechannel1 = MixerChannel.new("echette1", s, 2,2, outbus:outbus);
	s.sync;
	mixingboard = MixingBoard("apocalypse", nil, echettechannel1);
	s.sync;
	ingroup = Group.new(s, \addToHead);
	postgroup = Group.news, \addToTail);
	// //inbus = Bus.newFrom(s.inputBus,0,1);
	// ~testsound = (
	// 	instrument: \playbuf__1,
	// 	outbus: inbus,
	// 	bufnum: testbuf,
	// 	group: echettechannel1.fadergroup,
	// 	addAction: \addBefore,
	// 	sendGate: false,//won't loop if not told
	// ).play;
	// s.sync;
	//
	s.sync;
	state.putAll((
		outbus: outbus,
		inbus: inbus,
		ingroup: ingroup,
		echettechannel1: echettechannel1,
		fxgroup: fxgroup,
		mixingboard: mixingboard,
		postgroup: postgroup,
	));
	//
	// ~control = Bus.control(s, 4);
	// s.sync;
	// ~subcontrols = ~control.numChannels.collect(~control.subBus(_,1););

state[\limiter] = (
	 	instrument: \limi__2,
	 	group: postgroup,
	 	outbus:outbus,
	).play;
	~state=state;
};
)

a=~state.echettechannel1.play("pinkfilt", [\freq, 2000, \rq, 0.02, \out, ~state.echettechannel1.inbus.index]);

//////MIDI
// create an instance
n = NanoKontrol.new;

//assign actions
n.fader1.onChanged = {|val|
	"fader 1 changed".postln;
	val.postln;
};
n.topBt1.onPress = {|val| "top button 1 pressed".postln; val.postln };
n.topBt1.onRelease = {|val| "top button 1 released".postln; val.postln };
n.knob1.onChanged = {|val| "knob 1 changed".postln; val.postln };

//you can assign multiple items directly

//faders 1-9
n.faders.do{|fader, i|
	fader.onChanged= {|val| ("fader"+(i+1)).postln; val.postln }
};
