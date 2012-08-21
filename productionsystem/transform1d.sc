/*
AffineTransform1d: Function {
	var add=0, mul=1;

	*new {|add, mul|
		^this.newCopyArgs(add, mul);
	}
	value{|inbus| ^((value * mul) + add);}
}
*/