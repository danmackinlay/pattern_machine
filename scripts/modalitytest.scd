MIDIIn.connectAll;
MIDIIn.findPort("Ohm64", "Control Surface");
Quarks.gui;
MIDIMKtl.find;
//Connecting a synth to knob

(
k=MIDIMKtl('nnkn20');
k=MIDIMKtl('nnkn20', devDescName: 'nanoKONTROL2');
k=MIDIMKtl('nnkn20', -685957281, 1806932209, 'nanoKONTROL2');
k.reset; //reset controller to a clean state
k.explore(true);
k.explore(false);
k.elementNames;
~slider = k.esFor(\sl_1);
//~slidersig = k.signalFor(\sl_1);

//start synth
~synth = { |freq=400| LFNoise0.ar(freq)*0.2 }.play;

//associate each result EventSource with a synth
~slider.do{ |v| ~synth.set(\freq, v.linlin(0.0,1.0,100.0,4000.0) ) };
)

(
k = MIDIMKtl('nnkn20');
//first remove all actions from the controller.
k.reset;
k.elementNames.do({|name|
	var contr = k.esFor(name);
	contr.do({|val|
		[name, val].postln;
	});
});
)

Quarks.checkoutAll;
Quarks.gui;