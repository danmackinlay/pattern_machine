GUI.qt;
Server.default = s = ~serverboot.(\local, \builtin);
(
var window, slider, guiupdater, model, level, numberbox, setValueFunction, oscfunc;
//model
model = (myValue:1);
setValueFunction = {|value|
	[\setValueFunction, value].postln;
	model[\myValue] = value;
	model.changed(\value, value);
};
//view
window = Window("window!", Rect(100,10,288,80));
/*numberbox = NumberBox.new(window, Rect(20,20,44,20));
[\numberbox, numberbox].postln;
numberbox.value_(model[\myValue])
	.action({|view| [\nbview, view].postln;
		setValueFunction.value(view.value)}
);*/
//
numberbox = NumberBox.new(window, Rect(20,20,44,20))
	.postln
	//.value_(model[\myValue])
	.action({|view| [\nbview, view].postln;
		setValueFunction.value(view.value)}
);
[\numberbox, numberbox].postln;
//
slider = Slider.new(window, Rect(68,20,200,20));
[\slider, slider].postln;
slider.value_(model[\myValue])
	.action({|view| [\slview, view].postln; 		setValueFunction.value(view.value)}
);
level = LevelIndicator(window, Rect(272,20,5,20))
	.warning_(0.8)
	.critical_(1.0);
window.front;
window.onClose_({model.removeDependant(guiupdater); oscfunc.remove;});

//update
guiupdater = {|theChanger, what, val|
	{
		[\guiupdater, theChanger, what, val].postln;
		if(what == \value, {
			numberbox.value_(val);
			level.value_(val);
			slider.value_(val);
		});
	}.defer;
};
model.addDependant(guiupdater);
SynthDef("responsey", {
	SendTrig.kr(Dust.kr(2.0), 0, LFNoise1.kr(1, 0.5, 0.5));
}).play(s);
oscfunc = OSCFunc.newMatching(
	{|msg, time, addr, recvPort|
		setValueFunction.value(msg[3]);
		[\incoming, msg].postln;},
	'/tr', s.addr
);
~bits = (
	\model: model,
	\window: window,
	\oscfunc: oscfunc,
	\numberbox: numberbox,
	\slider: slider,
	\level: level
);
)
~bits[\slider];