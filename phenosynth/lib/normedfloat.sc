/* convert between 24 bit strings, and floats normed to [0,1).
These values are chosen to be lossless though SC3's number types.
*/

UnsignedUnitFloat {
  *fromBits { |bitArray|
    ^bitArray.reduce(UnsignedUnitFloat.reduceHelper);
  }
  *asBits{ |float|
    ^UnsignedUnitFloat.asInteger(float).asBinaryDigits(24);
  }
  *asInteger {|float|
    ^(float*16777216).asInt;
  }
  *reduceHelper { |left, right|
    ^(left*0.5 + right);
  }
}
SignedUnitFloat : UnsignedUnitFloat {
  /* convert between 25 bit strings, and floats normed to [-1,1) */
  
}