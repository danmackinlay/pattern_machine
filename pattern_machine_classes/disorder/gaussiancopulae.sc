/* Gaussian copula calcs and Pseudo-Ugens
TODO: make supplied RV optional

I simulate uniform marginal variables from the stipulated 2d copula distribution
see http://www.math.uni-leipzig.de/~tschmidt/TSchmidt_Copulas.pdf
or, for empirical copulae, http://www.mathworks.com.au/products/statistics/examples.html?file=/products/demos/shipping/stats/copulademo.html#17

This turns out to be easiest for Gaussian, t-copulae and Marshall-Olkin, and
only somewhat easy for some Archimedeans - specifically, Frank, Gumbel and Clayton.
Archimedean copulae have a single coupling parameter for a large variable set, which is nice. However, for bivariate coupling (and everything can be done pairwise if we want) Gaussians are yet simpler.

I'm not quote sure how to handle graceful conversions to UGens and also vector input values here. Compare:
~steps1 = Array.series(3001, 0, 1)/3000;
~steps33 = Array.series(3001, -1500, 1)/500;
~steps33.plot;
PSPhi(PSInvPhi(~steps1)).plot;
PSInvPhi(~steps1).plot;
PSPhi(~steps33).plot;
~steps33.collect(PSCorr(0.5, _)).plot;
PSCorr(0.9, ~steps33, {0.gauss(1)}.dup(~steps33.size)).plot;
PSCorr(0.9, ~steps33).plot;
PSCorr.v(0.9, ~steps33).plot;
*/

/*
Gaussian quantile function
Converts a uniform RV to a Gaussian on.
http://www.johndcook.com/blog/normal_cdf_inverse/
http://www.ccsenet.org/journal/index.php/jmr/article/view/5818 for some alternatives,
http://www.ams.org/journals/mcom/1968-22-101/S0025-5718-1968-0223070-2/ for some more
or http://www.cs.unm.edu/~jmk/cs531/NormalCDF.pdf
or http://eric.ed.gov/?id=ED064395
or http://www.johndcook.com/blog/normal_cdf_inverse/
*/

PSInvPhi {
	classvar c0 = 2.515517;
	classvar c1 = 0.802853;
	classvar c2 = 0.010328;
	classvar d0 = 1.432788;
	classvar d1 = 0.189269;
	classvar d2 = 0.001308;

	*new{|p|
		var isLeftSide, t, approxed;
		isLeftSide = (p<0.5);
		t = (-2.0 * isLeftSide.if({
			p.log
		}, {
			(1-p).log
		})).sqrt;
		approxed = this.halfInvPhi(t);
		^isLeftSide.if({approxed.neg}, {approxed});
	}
	*halfInvPhi{|t|
		^t - (((c2*t + c1)*t + c0) / 
			(((d2*t + d1)*t + d0)*t + 1.0));
	}
}

/*
Gaussian CDF
Converts a Gaussian RV to a uniform one.

From Mathematica using
MiniMaxApproximation[1/2 Erfc[-(x/Sqrt[2])],{x,{0,5},5,6},Bias->-0.0][[2,1]]
(0.5 + 0.14471 x - 0.0475766 x^2 + 0.0103247 x^3 + 0.00770533 x^4 - 0.00173843 x^5)/
(1 - 0.508492 x + 0.310832 x^2 - 0.0953128 x^3 +  0.02533 x^4 - 0.00331528 x^5 + 0.0000590544 x^6)

HornerForm[MiniMaxApproximation[1/2 Erfc[-(x/Sqrt[2])],{x,{0,5},5,6},Bias->-0.0][[2,1]]]
(8466.77 + x (2450.46 +  x (-805.641 + x (174.834 + (130.479 - 29.4377 x) x))))/
(16933.6 +  x (-8610.58 + x (5263.49 + x (-1613.98 + x (428.927 + x (-56.1395 + 1. x))))))

Alternative version, nicer:
HornerForm[MiniMaxApproximation[ (1/2 Erfc[-(x/Sqrt[2])] -1/2)/x, {x,{0.1,5},3,5}, Bias->-0][[2,1]] *x]
(x (-664.282+x (211.052 +(-54.6369-3.13535 x) x)))/
(-1665.13+x (529.232 +x (-414.991+x (80.874 +x (-28.0145+1.0x)))))
*/

PSPhi {
	classvar a1 = -3.13535;
	classvar a2 = -54.6369;
	classvar a3 = 211.052;
	classvar a4 = -664.282;

	classvar b2 = -28.0145;
	classvar b3 = 80.874;
	classvar b4 = -414.991;
	classvar b5 = 529.232;
	classvar b6 = -1665.13;

	*new{|p, minval=0.0, maxval=1.0|
		var flip;
		p = p.clip(-5,5);
		flip = (p<0.0).if(-1, 1);
		^(0.5+(flip*this.halfPhi(flip*p))).linlin(0.0,1.0,minval,maxval);
	}
	*halfPhi {|p|
		^(((a1*p+a2)*p+a3)*p+a4)*p /
			(((((p+b2)*p+b3)*p+b4)*p+b5)*p+b6);
	}
}

//Gaussian copula correlates
PSCorr {
	*new {|rho, thisRand, otherRand|
		//output a covariate with specified correlation rho, with default value
		^this.gaussGaussToGauss(rho, thisRand, otherRand ?? {0.gauss(1)});
	}
	*v {|rho, thisRand, otherRand|
		//output a covariate with specified correlation rho, with vector default value
		^this.gaussGaussToGauss(rho, thisRand, otherRand ?? {{0.gauss(1)}.dup(~steps33.size)});
	}
	*gaussGaussToGauss {|rho, thisRand, otherRand|
		//output a covariate with specified correlation rho
		^(thisRand * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
	*gaussGaussToUnif {|rho, thisRand, otherRand|
		^PSPhi(this.gaussGaussToGauss(rho, thisRand, otherRand));
	}
	*gaussUnifToGauss {|rho, thisRand, otherRand|
		^this.gaussGaussToGauss(rho, thisRand, PSInvPhi(otherRand));
	}
	*gaussUnifToUnif {|rho, thisRand, otherRand|
		^PSPhi(this.gaussUnifToGauss(rho, thisRand, otherRand));
	}
	*unifGaussToGauss {|rho, thisRand, otherRand|
		^this.gaussGaussToGauss(rho, PSInvPhi(thisRand), otherRand);
	}
	*unifGaussToUnif {|rho, thisRand, otherRand|
		^PSPhi(this.gaussGaussToGauss(rho, PSInvPhi(thisRand), otherRand));
	}
	*unifUnifToGauss {|rho, thisRand, otherRand|
		^this.gaussGaussToGauss(rho, PSInvPhi(thisRand), PSInvPhi(otherRand));
	}
	*unifUnifToUnif {|rho, thisRand, otherRand|
		^PSPhi(this.gaussUnifToGauss(rho, PSInvPhi(thisRand), PSInvPhi(otherRand)));
	}
}
