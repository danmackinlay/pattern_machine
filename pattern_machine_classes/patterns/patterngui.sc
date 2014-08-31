PcutdurGui : ObjectGui {
	guiBody { |layout|
		NumberEditor.bind(model,
			\start,
			spec: ControlSpec(minval:0.0, maxval:16.0, warp:\lin, step:16.reciprocal, default:model.start, units: "beats"),
			layout: layout,
			bounds:nil,labelWidth:nil);
		NumberEditor.bind(model,
			\dur,
			spec: ControlSpec(minval:0.0, maxval:16.0, warp:\lin, step:16.reciprocal, default:model.dur, units: "beats"),
			layout: layout,
			bounds:nil,labelWidth:nil);
		CXLabel(layout.startRow,"pattern");
		model.pattern.gui(layout);
	}
}