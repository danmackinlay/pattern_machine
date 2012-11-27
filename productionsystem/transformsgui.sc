Affine1Gui : ObjectGui {
	guiBody { |layout|
		NumberEditor.bind(model,
			\mul,
			spec: ControlSpec(minval:-16, maxval:16.0, warp:\lin, step:16.reciprocal, default:model.mul, units: ""),
			layout: layout,
			bounds:nil,labelWidth:nil);
		NumberEditor.bind(model,
			\add,
			spec: ControlSpec(minval:-16, maxval:16.0, warp:\lin, step:16.reciprocal, default:model.add, units: ""),
			layout: layout,
			bounds:nil,labelWidth:nil);
	}
}