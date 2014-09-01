/*
making sick synths by clever optimisation of the horrible parameter space

Check out sccode rand-n-step for array of synths examples
*/

//basic sine FM synth
(
fork {
	SynthDef.new(\basic_fm,
		{|out=0,
			gate=0,
			freq=440,
			modFreqRatio=2,
			fModAmp=0,
			aModAmp=0|
			var carrier, modulator;
			modulator = SinOsc.ar(freq: freq*modFreqRatio);
			carrier = SinOsc.ar(
				freq: freq,
				phase: fModAmp*modulator,
				mul: (1-aModAmp) + (aModAmp*modulator*0.5)
			);
			Out.ar(out,
				carrier
			);
		}, rates:[0.5, 0.05,0.05,0.05]
	).add;
	s.sync;
	~fmguy = Synth(\basic_fm, [
		\out, 0,
		\freq, 440,
		\modFreqRatio, 2,
		\fModAmp, 0,
		\aModAmp, 0
		], target: s,
		addAction:\addToTail
	);
}
)

(
~fmguy.set(\fModAmp, 0.1);
~fmguy.set(\fModAmp, 0.3);
~fmguy.set(\modFreqRatio, 3);
~fmguy.set(\modFreqRatio, 1);
~fmguy.set(\aModAmp, 0);
~fmguy.set(\aModAmp, 0.1);
~fmguy.set(\aModAmp, 2);
~fmguy.get(\out, _.postln);
)
/* TODO:
Envelope.
MIDI Control.
Pattern.
Panning.
*/
(
fork {
	SynthDef(\pitch_track, {
		|in, ampBus, freqBus, delay=0|
		var certainty, freq;
		in = In.ar(in);
		#freq, certainty = Tartini.kr(in);
		Out.kr(ampBus, DelayN.kr(
			Amplitude.kr(in),
			maxdelaytime: 5,
			delaytime: delay)
		);
		Out.kr(freqBus, DelayN.kr(
			freq,
			maxdelaytime: 5,
				delaytime: delay)
		);
	}).add;
	SynthDef(\mouseX, {
		|out, minval=0, maxval=1|
		Out.kr(out, MouseX.kr(
			minval: minval, maxval: maxval));
	}).add;
	SynthDef(\mouseY, {
		|out, minval=0, maxval=1|
		Out.kr(out, MouseY.kr(
			minval: minval, maxval: maxval));
	}).add;
	SynthDef(\audioIn, {
		|out|
		Out.ar(out, SoundIn.ar(0));
	}).add;
	s.sync;
	~inputBus=Bus.audio(s, 1);
	~mouseXBus=Bus.control(s, 1);
	~mouseYBus=Bus.control(s, 1);
	~freqBus=Bus.control(s, 1);
	~ampBus=Bus.control(s, 1);
	s.sync;
	~audioinguy = Synth(\audioIn, [
		\out, ~inputBus
	], s, addAction: \addToHead);
	s.sync;
	~pitchguy = Synth(\pitch_track, [
		\in, ~inputBus,
		\ampBus, ~ampBus,
		\freqBus, ~freqBus,
		\delay, 2
	], ~audioinguy, addAction: \addAfter);
	~mousexguy = Synth(\mouseX, [
		\out, ~mouseXBus
	], s, addAction: \addToHead);
	~mouseyguy = Synth(\mouseY, [
		\out, ~mouseYBus
	], s, addAction: \addToHead);
}
)
~ampBus.getSynchronous;
~freqBus.getSynchronous;
~fmguy.map(\aModAmp, ~mouseYBus);
~mouseyguy.set(\maxval, 2);
~fmguy.map(\fModAmp, ~mouseXBus);
~mousexguy.set(\maxval, 4);
~fmguy.map(\freq, ~freqBus);
~pitchguy.set(\delay, 0);
//////////////////////////
SynthDef.new(\fmraw, {|freq,
	harmonicfreqs,
	ringModAmp,
	fModAmp,
	attacks,
	decays,
	sustains,
	releases,
	pans,
	trigger|
	var oscs;
}).add;


SynthDef.new(\fmapped, {|freq,
	paramMap,
	mapBus,
	trigger|
}).add;

