/* Gaussian copula calcs and Pseudo-Ugens*/
// Todo: make supplied RV optional

PSInvPsi {
	//gaussian quantile function
	//http://home.online.no/~pjacklam/notes/invnorm/#The_algorithm
	classvar a1 = -3.969683028665376e+01;
	classvar a2 =  2.209460984245205e+02;
	classvar a3 = -2.759285104469687e+02;
	classvar a4 =  1.383577518672690e+02;
	classvar a5 = -3.066479806614716e+01;
	classvar a6 =  2.506628277459239e+00;

	classvar b1 = -5.447609879822406e+01;
	classvar b2 =  1.615858368580409e+02;
	classvar b3 = -1.556989798598866e+02;
	classvar b4 =  6.680131188771972e+01;
	classvar b5 = -1.328068155288572e+01;

	classvar c1 = -7.784894002430293e-03;
	classvar c2 = -3.223964580411365e-01;
	classvar c3 = -2.400758277161838e+00;
	classvar c4 = -2.549732539343734e+00;
	classvar c5 =  4.374664141464968e+00;
	classvar c6 =  2.938163982698783e+00;

	classvar d1 =  7.784695709041462e-03;
	classvar d2 =  3.224671290700398e-01;
	classvar d3 =  2.445134137142996e+00;
	classvar d4 =  3.754408661907416e+00;

	classvar pLow = 0.02425;

	*new{|p|
		var isRightSide;
		isRightSide = (p>0.5)*1;
		^(1-(2*isRightSide))*this.leftSide(p.fold(0.0,0.5));
	}
	*leftSide{|p|
		var isLow;
		isLow = (p<pLow)*1;
		^(isLow*this.lowSection(p)+((1-isLow)*this.midSection(p)));
	}
	*midSection {|p|
		var q,r;
		q = p-0.5;
		r = q.squared;
		^(((((a1*r+a2)*r+a3)*r+a4)*r+a5)*r+a6)*q /
			(((((b1*r+b2)*r+b3)*r+b4)*r+b5)*r+1);
	}
	*lowSection {|p|
		var q;
		p = p.clip(0.00000001,0.99999999);
		q = (-2*log(p)).sqrt;
		^(((((c1*q+c2)*q+c3)*q+c4)*q+c5)*q+c6) /
			((((d1*q+d2)*q+d3)*q+d4)*q+1);
	}
}

/*
gaussian CDF
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

PSPsi {
	classvar a1 = -3.13535;
	classvar a2 = -54.6369;
	classvar a3 = 211.052;
	classvar a4 = -664.282;

	classvar b2 = -28.0145;
	classvar b3 = 80.874;
	classvar b4 = -414.991;
	classvar b5 = 529.232;
	classvar b6 = -1665.13;

	*new{|p|
		var flip;
		p = p.clip(-5,5);
		flip = 1-((p<0.0)*2);
		^0.5+(flip*this.halfPsi(flip*p));
	}
	*halfPsi {|p|
		^(((a1*p+a2)*p+a3)*p+a4)*p /
			(((((p+b2)*p+b3)*p+b4)*p+b5)*p+b6);
	}
}


PSGaussCorrelate {
	*gaussianize {|inUniform|
		//transform a Uniform RV to a Gaussian RV
		^PSPsi(inUniform);
	}
	*degaussianize {|inGaussian|
		//transform a Gaussian RV to a Uniform one
		^PSInvPsi(inGaussian);
	}
	*corr {|rho, inGaussian|
		//output a covariate with specified correlation rho
		var otherRand, inDim;
		inDim = inGaussian.size;
		otherRand = (inDim>0).if({
			//cast to array if we want many values at once.
			{0.gauss(1)}.dup(inDim);
		},{
			0.gauss(1);
		});
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
}

PSUGaussCorrelate : PSGaussCorrelate {
	*kr {|rho, inGaussian|
		var otherRand = this.krGaussianize(WhiteNoise.kr(0.5, 0.5));
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
	*ar {|rho, inGaussian|
		var otherRand = this.arGaussianize(WhiteNoise.ar(0.5, 0.5));
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
}
