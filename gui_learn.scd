/* TODO:
 * Check out ObjectGui helpfile to make autogui action easy.
 * how do I make this size itself dynamically as claimed in the world
 * of QtGui?
 */

GUI.qt;
Server.default = s = ~serverboot.(\local, \builtin);
(
var window, slider, guiupdater, model, level, suppressionwidget, activationwidget, ratewidget, tempowidget, modelSetter, clock, worker, ringconvolve;
//model
model = (
	suppressions: [1,0,0,0.5,1,0.5,0,0.5,0,1,0,0],
	activations: [1] ++ 0.dup(11),
	tempo: 120,
	decayRate: 0.1
);
ringconvolve = {|left, right|
	var convolved = left.collect{|val, i|
		var dot = left * (right.rotate(i)); //backwards?
		dot.postln;
		dot.sum;
	};
};
//view
window = FlowView(bounds:300@300, windowTitle: "window!").front;
CmdPeriod.doOnce({window.close});

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
tempowidget = EZSlider.new(
	parent: window,
	bounds: Point(window.bounds.width*0.9, 16),
	label: "tempo",
	controlSpec: ControlSpec.new(40, 200,
		\exponential,
		default: model.tempo,
		units:\bpm),
	initVal: 120,
	action: {|view| modelSetter.value(\tempo, view.value);}
);
window.onClose_({
	model.removeDependant(guiupdater);
});

//controller
modelSetter = {|statekey, stateval|
	model[statekey] = stateval;
	model.changed(statekey, stateval);
};
guiupdater = {|theChanger, what, val|
	{
		what.switch(
			\suppressions, { suppressionwidget.value_(val);},
			\activations, { activationwidget.value_(val);},
			\tempo, { tempowidget.value_(val);}
		);
	}.defer;
};
model.addDependant(guiupdater);
~bits = (
	\model: model,
	\window: window,
	\suppressionwidget: suppressionwidget,
	\slider: slider,
	\level: level
);

)
~bits.window.bounds.width

~ringconvolve = {|left, right|
	left.collect{|val, i|
		(left * (right.rotate(i))).sum; //backwards?
	};
};

~ringconvolve.([1,0,1], [1,2,3]);
