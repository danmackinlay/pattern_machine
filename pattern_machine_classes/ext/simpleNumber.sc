+ SimpleNumber {
	roundDown {|val|
		var rounded = this.round(val);
		(rounded>this).if({^(rounded-val)},{^rounded});
	}
}