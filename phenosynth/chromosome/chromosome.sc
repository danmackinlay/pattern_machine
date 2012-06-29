PSChromosome {
	var <>ints; // May sa well store it as this. Fast.
	bits {
		^ints.collect(UnitFloat.bitsFromInt(_));
	}
	bits_ {|bitArray|
		ints = bitArray.clump(UnitFloat.nbits)
	}
	floats_ {|floatArray|
		ints = floatArray.collect(UnitFloat.bitsFromFloats(_));
	}
	floats {
		^ints.collect(UnitFloat.floatsFromInt(_))
	}
}