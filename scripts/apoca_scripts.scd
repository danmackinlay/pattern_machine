/*
Apocalypse

Ideas:
* Some kind of sequencing things based on order parameters, pulling in and out of chaos
* Bulk sample loading based on MIR
* the param mapping thing
* wiimote!
* feedme script too?
* ipad setup
* sync with team members
* control ableton with SC
	* therefore, isolate MIDI output when necc
* feedback effects?
* stateful algorithm to navigate through with wiimote
* mixing gains of several doohickeys
	* BusMeter?
	* ddwChannelStrip?
		SynthDef.new("pinkfilt", {
			arg	outbus,	// outbus is the standard name used by MixerChannel
				freq, rq;
			Out.ar(outbus, RLPF.ar(PinkNoise.ar, freq, rq));
		}).send(s);

		m = MixerChannel.new("pinkfilt", s);	// defaults to mono-to-stereo

		a = m.play("pinkfilt", [\freq, 2000, \rq, 0.02]);

		m.free;	// all synths disappear

		//Note that if you use MixerChannel.play, you don't have to specify the bus number as long as your synthdef uses outbus as the output bus argument. Otherwise, do this:

		a = m.play("pinkfilt", [\freq, 2000, \rq, 0.02, \out, m.inbus.index]);

		// Any effect synthdefs you write should read the input signal from outbus and use ReplaceOut.ar(outbus...). If you want the input signal to be included in the effect's output, it's advisable to include an argument for wet/dry level rather than simply using Out to add the effect to the bus, because you have more control:

		SynthDef.new("fx/chorus1x1", {
			arg outbus, delay = 0.01, freq = 0.2, depth = 0.05, wet = 0.5;
			var in, out;
			in = In.ar(outbus, 1);
			out = DelayN.ar(in, 1, SinOsc.ar(freq, 0, depth, delay));
			ReplaceOut.ar(outbus, in*(1-wet).sqrt + out*wet.sqrt);	// equal power
		}).send(s);

		m.playfx("fx/chorus1x1");	// so it goes to effectgroup
	
	* RedMixerChannel?
		a= RedMixerChannel(#[0, 1]);
		b= Pbind(\pan, Pseq([-1, 1], inf), \amp, 0.5).play
		c= RedMixerChannelGUI(a, name: "testing")
		a.cvs.eqHi.input= 1
		a.cvs.eqHi.input= 0
		a.free
		b.stop
		c.close
* Jack routing into Live?
* audio-input-driven effects
* automatic sample-library stuff selection
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
var inbus, outbus, ingroup, voxgroup, fxgroup, postgroup, testsample, testbuf, envBuf, state, freqMap, minFreq=55, nOctaves=8, nBpBandsPerOctave=1, nBpBandsTotal, allBpFreqs ,bwr;

state = ();

fork{
	ingroup = Group.new(s, \addToHead);
	//inbus = Bus.newFrom(s.inputBus,0,1);
	inbus = Bus.audio(s,1);
	outbus = Bus.new(\audio, 0, 2, s);
	testbuf = Buffer.read(s, testsample);
	s.sync;
	~testbuf = testbuf;
	~testsound = (
		instrument: \playbuf__1,
		out: inbus,
		bufnum: testbuf,
		group: ingroup,
		sendGate: false,//won't loop if not told
	).play;

	state.putAll((
		outbus: outbus,
		inbus: inbus,
		ingroup: ingroup,
		voxgroup: voxgroup,
		fxgroup: fxgroup,
		postgroup: postgroup,
	));
	voxgroup = Group.new(s, \addToTail);
	s.sync;
	fxgroup = Group.new(s, \addToTail);
	s.sync;
	postgroup = Group.new(s, \addToTail);
	s.sync;

	~control = Bus.control(s, 4);
	s.sync;
	~subcontrols = ~control.numChannels.collect(~control.subBus(_,1););
	this.executeFile(~pmscripts +/+ "apoca_synths.scd");
	~limiter = (
		instrument: soundin__1,
		group: postgroup,
		out:outbus,
	).play;
	~limiter = (
		instrument: \limi__2,
		group: postgroup,
		out:outbus,
	).play;
)

)



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
