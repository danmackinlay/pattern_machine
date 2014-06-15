+ SimpleNumber {
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
}