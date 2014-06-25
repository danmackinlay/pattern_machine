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
*/
////////
s=~serverboot.(prox:\local, device:\internal);
~apoca_samp = "/Users/dan/Dropbox/cheeky\ shares/apocalypse";
Quarks.gui
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
var testsample, testbuf, envBuf;
var state;
var echettechannel1, mixingboard;

state = ();

fork{
	inbus = Bus.audio(s,1);
	outbus = Bus.new(\audio, 0, 2, s);
	//testbuf = Buffer.read(s, testsample);
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	s.sync;
	echettechannel1 = MixerChannel.new("echette1", s, 2,2);
	s.sync;
	mixingboard = MixingBoard("apocalypse", nil, echettechannel1);
	// s.sync;
//		a = echettechannel1.play("pinkfilt", [\freq, 2000, \rq, 0.02]);
		//Note that if you use MixerChannel.play, you don't have to specify the bus number as long as your synthdef uses outbus as the output bus argument. Otherwise, do this:

//		a = echettechannel1.play("pinkfilt", [\freq, 2000, \rq, 0.02, \out, echettechannel1.inbus.index]);

		// Any effect synthdefs you write should read the input signal from outbus and use ReplaceOut.ar(outbus...). If you want the input signal to be included in the effect's output, it's advisable to include an argument for wet/dry level rather than simply using Out to add the effect to the bus, because you have more control:
	//
	// SynthDef.new("fx/chorus1x1", {
	// 	arg outbus, delay = 0.01, freq = 0.2, depth = 0.05, wet = 0.5;
	// 	var in, out;
	// 	in = In.ar(outbus, 1);
	// 	out = DelayN.ar(in, 1, SinOsc.ar(freq, 0, depth, delay));
	// 	ReplaceOut.ar(outbus, in*(1-wet).sqrt + out*wet.sqrt);	// equal power
	// }).add;
	//
	// echettechannel1.playfx("fx/chorus1x1");	// so it goes to effectgroup
	// ingroup = Group.new(s, \addToHead);
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
	// postgroup = Group.new(echettechannel1.fadergroup, \addAfterl);
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
	//
	// ~limiter = (
	// 	instrument: \limi__2,
	// 	group: postgroup,
	// 	outbus:outbus,
	// ).play;
	[2,state].postln;
	~state=state;
};
[1,state].postln;
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
