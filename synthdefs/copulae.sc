/* Gaussian copula calcs and Pseudo-Ugens*/
// Todo: currenlty the (4 sigma) buffer is inefficient because
//		1) it is symmetric and
//		2) many samples are at the fringes.
//      This could be made more efficient by polynomial warping and/or symmetrisation.
// Todo: triggered version
// Todo: there are off-by-one errors in the LUTs
// Todo: make supplied RV optional

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
