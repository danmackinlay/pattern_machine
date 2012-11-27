PcutdurGui : ObjectGui {
	guiBody { |layout|
		CXLabel(layout.startRow,"start");
		model.start.gui(layout);
		CXLabel(layout.startRow,"dur");
		model.dur.gui(layout);
		CXLabel(layout.startRow,"pattern");
		model.pattern.gui(layout);
	}
}