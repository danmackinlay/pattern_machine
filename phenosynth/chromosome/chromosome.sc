//Todo: do everything with RawArray subtypes. Int8Array for bits, maybe?
PSChromosome {
	var <bits;  //cache bit array for manual parsing
	var <counter = 0;
	
	*new{
		^super.new.init;
	}
	*newBits{|bitArray|
		^this.new.bits_(bitArray);
	}
	*newFloats{|bitArray|
		^this.new.floats_(bitArray);
	}
	init{
		bits=[];
	}
	printOn { arg stream;
		stream << this.class.asString << "(" << bits.join << ")";
	}

	//default chromosome-as-array-of-data-type business.
	ints_ {|intArray|
		bits = intArray.collect(UnitFloat.bitsFromInt(_)).flat;
	}
	ints {
		^bits.clump(UnitFloat.nbits).collect(UnitFloat.intFromBits(_));
	}
	bits_ {|bitArray|
		bits = bitArray;
	}
	floats_ {|floatArray|
		bits = floatArray.collect(UnitFloat.bitsFromFloat(_)).flat;
	}
	floats {
		^bits.clump(UnitFloat.nbits).collect(UnitFloat.floatFromBits(_))
	}
	
	//support for ad-hoc chromosome parsing
	reset {
		counter=0;
	}
	parseBits{|nbits=24|
		var chunk = bits[counter..(counter+nbits-1)];
		counter = counter + nbits;
		^chunk;
	}
	parseFloat{|nbits=24|
		^UnitFloat.floatsFromInt(this.parseBits(nbits));
	}
	parseInt{|nbits=24|
		^UnitFloat.floatsFromInt(this.parseBits(nbits));
	}
}