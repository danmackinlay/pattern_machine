/*
Client-side IIR value filtering.

Would be more elegant, I suppose, to implement this as some kind of stream consumer.
*/

//One-pole lowpass
ValueLag {
    var <>coef;
    var <>state;
    
    *new {|coef=0.1, initial=0|
        ^super.newCopyArgs(coef, initial);
    }
    nibble {|nextval=0|
        state = (coef*nextval) + ((1-coef)*state);
        ^state;
    }
	value {
		^state;
	}
}

/*
//Two one-pole lowpasses in series
ValueLag2 : ValueLag {
    nibble {|nextval=0|
		var onceFiltered;
		super.nibble(nextval);
		super.nibble(nextval);
		^state;
    }
}
//no it isn't. Am doing this wrong.
*/