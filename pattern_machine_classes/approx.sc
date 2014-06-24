/*
polynomial approximation for things that are tedious to set up lookup buffers for
*/
//maps to or from [-1,1]
CentredApprox {
	*halfCos {|x|
		// half-cosine window on -1,1
		// this 4th order approximation is accurate to .05dB and attains all extrema exactly.
		// the cost is that mean error is not zero not centred, undershooting on the shoulders.
		// 6th order doesn't improve much and is much uglier
		// No bounds checking is done.
		// consts given to 64 bit precision to make the endpoints be neat 0 only for tidiness.
		var x2 = x.squared;
		^1.0 + (x2*(-1.21460183660255169 + (0.2146018366025516904*x2)));
	}
	*sqrtHalfCos {|x|
		// sqrt half-cosine window on -1,1
		// this 6th order approximation is accurate to about 0.2dB in the body, but  bad in the tails where the envelope gets infintely steep.
		// error is not vertically centred, undershooting on the shoulders.
		// No bounds checking is done.
		// consts given to 64 bit precision to make the endpoints be neat 0 only for tidiness.
		// Could be better done with warped rational approximation. later.
		var x2 = x.squared;
		^1.00000000000000000 + (x2 * (-0.764879340394491635 + (
		    x2 * (0.616868399844512129 - (0.851989059450020494 *x2)))));
	}
	*halfSine {|x|
		//half sine(pi*x/2) on -1,1. CF LFCub
		^x*(1.57079632679489662 - 0.570796326794896619 * x.squared);
	}
}