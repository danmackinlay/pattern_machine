/*
polynomial approximation for things that are tedious to set up lookup buffers for
*/
//maps to or from [-1,1]
CentredApprox {
	*halfSine {|x|
		// half-sine window on -1,1
		// this 4th order approximation is accurate to .05dB and attains all extrema exactly.
		// the cost is that mean error is not zero not centred, undershooting on the shoulders.
		// 6th order doesn't improve much and is much uglier
		// No bounds checking is done.
		// consts given to 64 bit precision to make the endpoints be neat 0 only for tidiness.
		var x2 = x.squared;
		^1.0 + (x2*(-1.21460183660255169 + (0.2146018366025516904*x2)));
	}
	*sqrtHalfSine {|x|
		// sqrt half-sine window on -1,1
		// this 6th order approximation is accurate to about 0.2dB in the body, but infinitely bad in the tails where the envelope gets infintely steep.
		// the cost is that it is not centred, undershooting on the shoulders.
		// No bounds checking is done.
		// consts given to 64 bit precision to make the endpoints be neat 0 only for tidiness.
		// Could be ebtter done with warped rational apprxomation. later.
		var x2 = x.squared;
		1.00000000000000000 + (x2 * (-0.764879340394491635 + (
		    x2 * (0.616868399844512129 - (0.851989059450020494 *x2)))))
	}
}