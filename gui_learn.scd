/* TODO:
 * Checkout ObjectGui helpfile to make autogui action easy.
 */

GUI.qt;
Server.default = s = ~serverboot.(\local, \builtin);
(
var window, slider, guiupdater, model, level, numberbox, modelSetter, oscfunc;
//model
model = (stateValue1: 1);

//view
window = Window("window!", Rect(100,10,288,80));
numberbox = NumberBox(window, Rect(20,20,44,20))
	.value_(model[\stateValue1])
	.action_({|view|
		modelSetter.value(\stateValue1, view.value);
	});
slider = Slider(window, Rect(68,20,200,20))
	.value_(model[\stateValue1])
	.action_({|view|
		modelSetter.value(\stateValue1, view.value);});
level = LevelIndicator(window, Rect(272,20,5,20))
	.warning_(0.8)
	.critical_(1.0);
window.front;
window.onClose_({
	model.removeDependant(guiupdater);
	oscfunc.remove;});
CmdPeriod.doOnce({window.close});
//controller
modelSetter = {|statekey, stateval|
	model[statekey] = stateval;
	model.changed(statekey, stateval);
};
guiupdater = {|theChanger, what, val|
	{
		if(what == \stateValue1, {
			numberbox.value_(val);
			level.value_(val);
			slider.value_(val);
		});
	}.defer;
};
model.addDependant(guiupdater);

//Another input
SynthDef("responsey", {
	SendTrig.kr(Dust.kr(2.0), 0, LFNoise1.kr(1, 0.5, 0.5));
}).play(s);
oscfunc = OSCFunc.newMatching(
	{|msg, time, addr, recvPort|
		modelSetter.value(\stateValue1, msg[3]);
	}, '/tr', s.addr
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
