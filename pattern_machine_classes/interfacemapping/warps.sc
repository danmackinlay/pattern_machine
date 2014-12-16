AtanWarp : Warp {
	var <top, <bottom, <scale;
	*initClass {
		Warp.warps.put(\atan, AtanWarp)
	}
	//AFAICT you can't actually pass arguments to warps; mutate them after the fact.
	*new { arg spec, scale = 2;
		^super.new(spec.asSpec).scale_(scale);
	}
	scale_ { arg argScale;
		scale = argScale;
		bottom = scale.neg.atan;
		top = scale.atan;
	}
	map { arg value;
		// maps a value from [0..1] to spec range
		^value.linlin(0,1, scale.neg, scale).atan.linlin(bottom, top, spec.minval, spec.maxval);
	}
	unmap { arg value;
		// maps a value from spec range to [0..1]
		^value.linlin(spec.minval, spec.maxval, bottom, top).tan.linlin(scale.neg, scale, 0, 1);
	}
	//argument passing to warps is broken AFAIK, so this asSpecifier shit will discard the scale argument. Sorry.
	asSpecifier { ^\atan }
}
TanWarp : Warp {
	var <top, <bottom, <scale;
	*initClass {
		Warp.warps.put(\tan, TanWarp)
	}
	//AFAICT you can't actually pass arguments to warps; mutate them after the fact.
	*new { arg spec, scale = 2;
		^super.new(spec.asSpec).scale_(scale);
	}
	scale_ { arg argScale;
		scale = argScale;
		bottom = scale.neg.atan;
		top = scale.atan;
	}
	unmap { arg value;
		// maps a value from spec range to [0..1]
		^value.linlin(spec.minval, spec.maxval, scale.neg, scale).atan.linlin(bottom, top, 0, 1);
	}
	map { arg value;
		// maps a value from [0..1] to spec range
		^value.linlin(0, 1, bottom, top).tan.linlin(scale.neg, scale, spec.minval, spec.maxval);
	}
	//argument passing to warps is broken AFAIK, so this asSpecifier shit will discard the scale argument. Sorry.
	asSpecifier { ^\atan }
}
