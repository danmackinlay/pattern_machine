/* Gaussian copula calcs and Pseudo-Ugens*/
// Todo: currenlty the (4 sigma) buffer is inefficient because
//		1) it is symmetric and
//		2) many samples are at the fringes.
//	  This could be made more efficient by polynomial warping and/or symmetrisation.
// Todo: triggered version
// Todo: there are off-by-one errors in the LUTs
// Todo: make supplied RV optional

PSInvNorm {
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
		isRightSide = (p>0.5).asInt;
		^(1-(2*isRightSide))*this.leftSide(p.fold(0.0,0.5));
	}
	*leftSide{|p|
		var isLow;
		isLow = (p<pLow).asInt;
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

PSGaussCorrelate {
	classvar <arr_Erf, <arr_iErf;
	classvar <length=513;

	*initClass{
		StartUp.add({
			this.init;
		});
	}
	*init {
		//pretty sure there is an off-by-one error here. 
		arr_Erf = Array.interpolation(length,-4,4).collect(_.gaussCurve).integrate.normalize;
		arr_iErf = Array.interpolation(length).collect({|v| arr_Erf.indexInBetween(v)}).normalize(-4,4);
	}
	*gaussianize {|inUniform|
		//transform a Uniform RV to a Gaussian RV
		^arr_iErf.blendAt(inUniform*(length-1));
	}
	*degaussianize {|inGaussian|
		//transform a Gaussian RV to a Uniform one
		^arr_Erf.blendAt(inGaussian.linlin(-4, 4, 0, (length-1)));
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
	*krGaussianize {|inUniform|
		//UGen-happy version
		^IndexL.kr(LocalBuf.newFrom(arr_iErf), inUniform * (length-1));
	}
	*krDegaussianize {|inUniform|
		//UGen-happy version
		^IndexL.kr(LocalBuf.newFrom(arr_Erf), inUniform.linlin(-4, 4, 0, (length-1)));
	}
	*kr {|rho, inGaussian|
		var otherRand = this.krGaussianize(WhiteNoise.kr(0.5, 0.5));
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
	*arGaussianize {|inUniform|
		//UGen-happy version
		^IndexL.ar(LocalBuf.newFrom(arr_iErf), inUniform * (length-1));
	}
	*arDegaussianize {|inUniform|
		//UGen-happy version
		^IndexL.ar(LocalBuf.newFrom(arr_Erf), inUniform.linlin(-4, 4, 0, (length-1)));
	}
	*ar {|rho, inGaussian|
		var otherRand = this.arGaussianize(WhiteNoise.ar(0.5, 0.5));
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
}
