//Ripped off from mmExtensions' InterpolatorGui
ParamWalkerGui : ObjectGui {
	var <>actions, <layout, <iMadeMasterLayout = false;
	*new { arg model;
		var new;
		new = super.new;
		new.model_(model);
		^new.init;
	}

	init {
		actions = IdentityDictionary[];
	}

	gui { arg parent, bounds ... args;
		var layout;
		bounds = bounds ?? this.calculateLayoutSize;
		layout=this.guify(parent,bounds);
		layout.flow({ arg layout;
			this.view = layout;
			this.writeName(layout);
			this.performList(\guiBody,[layout] ++ args);
		},bounds).background_(this.background);
		//if you created it, front it
		if(parent.isNil,{
			layout.resizeToFit(true,true);
			layout.front;
		});
		^layout;
	}

	guify { arg parent,bounds,title;
		// converts the parent to a FlowView or compatible object
		// thus creating a window from nil if needed
		// registers to remove self as dependent on model if window closes
		if(bounds.notNil,{
			bounds = bounds.asRect;
		});
		if(parent.isNil,{
			parent = PageLayout(
				title ?? {model.asString.copyRange(0,50)},
				bounds,
				front:false
			);
			iMadeMasterLayout = true;
		},{
			parent = parent.asPageLayout(bounds);
		});
		// i am not really a view in the hierarchy
		parent.removeOnClose(this);
		^parent
	}

	calculateLayoutSize {
		^Rect(0,0,400,400)
	}
	
	update { arg model, what ... args;
		var action;
		action = actions.at(what);
		if (action.notNil, {
			action.valueArray(model, what, args);
		});
	}
}