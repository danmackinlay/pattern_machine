/* utility to convert between 24 bit strings, and floats normed to [0,1).
These values are chosen to be lossless though all SC3's auto-cooerced number types.
*/

/* Tests should look something like this:
UnitFloat.bitsFromFloat(UnitFloat.floatFromBits([1,0,0,0,0,1,1,0,1,1,0,1]));
UnitFloat.floatFromBits(UnitFloat.bitsFromFloat(0.336));
UnitFloat.intFromFloat(UnitFloat.floatFromInt(5633));
UnitFloat.intFromBits(UnitFloat.bitsFromInt(27689));
*/
UnitFloat {
	classvar <nbits=24;
	classvar <maxInt=16777216;
	*floatFromBits { |bitArray|
		^this.floatFromInt(this.intFromBits(bitArray));
	}
	*floatFromInt { |int|
		^int/maxInt;
	}
	*bitsFromFloat{ |float|
		^this.bitsFromInt(this.intFromFloat(float));
	}
	*bitsFromInt{ |int|
		^int.asDigits(2, nbits);
	}
	*intFromFloat {|float|
		^((float*2)+0.5).floor.asInt;
	}
	*intFromBits {|bitArray|
		^bitArray.convertDigits(2);
	}
}
