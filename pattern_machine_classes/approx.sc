/*
polynomial approximation for things that are tedious to set up lookup buffers for
*/
//maps to or from [-1,1]
CentredApprox {
	*halfSine {|x|
		// half-sine window on -1,1
		// this 4th order approximation is accurate to .05dB and attains all extrema exactly.
		// the cost is that it is not centred, undershooting on the shoulders.
		// 6th order doesn't improve much and is much uglier
		// No bounds checking is done.
		// consts given to 64 bit precision to make the endpoints be neat 0 only for tidiness.
		var x2 = x.squared;
		^1.0 + (x2*(-1.21460183660255169 + (0.2146018366025516904*x2)));
	}
}