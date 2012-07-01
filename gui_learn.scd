/* TODO:
 * Check out ObjectGui helpfile to make autogui action easy.
 */

GUI.qt;
Server.default = s = ~serverboot.(\local, \builtin);
(
var window, slider, guiupdater, model, level, suppressionwidget, activationwidget, modelSetter, oscfunc;
//model
model = (suppressions: [1,0,0,0.5,1,0.5,0,0.5,0,1,0,0], activations: 0.dup(12));

//view
window = FlowView(bounds:300@300, windowTitle: "window!").front;

suppressionwidget = MultiSliderView(window, 
		Point(window.bounds.width*0.9, 100))
	.size_(model[\suppressions])
	.value_(model[\suppressions])
	.elasticMode_(1)
	.drawRects_(true)
	.isFilled_(true)
	.action_({|view|
		modelSetter.value(\suppressions, view.value);
	});
window.startRow;
activationwidget = MultiSliderView(window,
		Point(window.bounds.width*0.9, 100))
	.size_(model[\activations])
	.value_(model[\activations])
	.elasticMode_(1)
	.drawRects_(true)
	.isFilled_(true)
	.action_({|view|
		modelSetter.value(\activations, view.value);
	});
window.startRow;

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
		what.switch(
			\suppressions, { suppressionwidget.value_(val);},
			\activations, { activationwidget.value_(val);}
		);
	}.defer;
};
model.addDependant(guiupdater);

~bits = (
	\model: model,
	\window: window,
	\oscfunc: oscfunc,
	\suppressionwidget: suppressionwidget,
	\slider: slider,
	\level: level
);
)
~bits.window.bounds.width