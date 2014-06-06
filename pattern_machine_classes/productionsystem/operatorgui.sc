PcompGui : ObjectGui {
	guiBody { arg layout;
		CXLabel(layout.startRow,"operation:");
		model.fn.gui(layout);
	}
}