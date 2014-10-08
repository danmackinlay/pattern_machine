+ SimpleNumber {
	//floor, for non-integer factors
	roundDown {|val|
		var rounded = this.round(val);
		(rounded>this).if({^(rounded-val)},{^rounded});
	}
	//clipping to the region [min{a,b}, max{a,b}]
	psclip {|a,b| ^(a<b).if({this.clip(a,b)},{this.clip(b,a)})}
	// linear mapping where if min>max, the mapping is inverted.
	// e.g.
	// Array.series(21,-0.5,0.1).collect({|x| x.pslinlin(0,1,5,4)});
	pslinlin {|inMin=(-1.0),inMax=1.0,outMin=0.0,outMax=100.0|
		^(this.psclip(inMin,inMax)-inMin)/(inMax-inMin)*(outMax-outMin)+outMin;
	}
	// clip to a range by doubling or halving
	// you are in charge of making sure that ubound>=2*lbound, and both positive
	octaveClip {|lbound=1.0, ubound=2.0|
		^this.octaveClipDown(ubound
			).octaveClipUp(lbound)
	}
	octaveClipDown {|ubound=2.0|
		(this<=ubound).if({
			^this;
		}, {
			^this * (2**(((ubound.log2)-(this.log2)).floor));
		});
	}
	octaveClipUp{|lbound=1.0|
		(this>=lbound).if({
			^this;
		}, {
			^this * (2**(((lbound.log2)-(this.log2)).ceil));
		});
	}
	//clip to a range by subtracting, e.g. octaves off
	// you are in charge of making sure that ubound>=base+lbound
	harmonicWrap{|lbound=64, ubound=76, base=12|
		^this.harmonicWrapDown(ubound, base
			).harmonicWrapUp(lbound, base)
	}
	harmonicWrapDown {|ubound=76, base=12|
		(this<=ubound).if({
			^this;
		}, {
			^this - ((((this-ubound)/base).ceil)*base);
		});
	}
	harmonicWrapUp {|lbound=64, base=12|
		(this>=lbound).if({
			^this;
		}, {
			^this + ((((lbound-this)/base).ceil)*base);
		});
	}
	offsetMod {|lbound=64, ubound=76|
		^(this-lbound) % (ubound-lbound) + lbound;
	}
	offsetModBase {|lbound=64, ubound=76, base=12|
		^this.offsetMod(lbound, lbound + (ubound-lbound).roundDown(base));
	}
}