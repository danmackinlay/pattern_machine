/*Gaussian copula business*/
//Todo: currenlty the (4 sigma) buffer is inefficient because 1) it is symmetric and 2) many samples are at the fringes. 
//      Thist could be made more efficient by polynomial warping and symmetrisation.
// Todo: triggered version
// Todo: there are off-by-one errors in the LUTs
// Todo: make supplied RV optional

PSGaussCopula {
	classvar <arr_Erf, <arr_iErf;
	classvar <length=513;
	classvar <dict_Servers;
	*initClass{
		StartUp.add({
			this.init;
		});
	}
	*init {
		dict_Servers = ();
		arr_Erf = Array.interpolation(length,-4,4).collect(_.gaussCurve).integrate.normalize;
		arr_iErf = Array.interpolation(length).collect({|v| arr_Erf.indexInBetween(v)}).normalize(-4,4);
	}
	*krGaussianize {|inUniform|
		//transform a univorm RV to a Gaussian RV
		^arr_iErf.blendAt(inUniform*(length-1));
	}
	*krDegaussianize {|inGaussian|
		//transform a Gaussian RV to a Uniform one
		^arr_iErf.indexInBetween(inGaussian|)/(length-1);
	}
	*correlate {|rho, inGaussian|
		var otherRand = 0.gauss;
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
	*krCorrelate {|rho, inGaussian|
		var otherRand = this.krGaussianize(WhiteNoise.kr(0.5, 0.5));
		^(inGaussian * rho) + ((1-(rho.squared)).sqrt * otherRand);
	}
}