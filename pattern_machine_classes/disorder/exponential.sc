+ SimpleNumber {
	//This is the p-param of a 0-indexed geometric RV
	unifGeomP {arg unif;
		^(unif.log/((1-this).log)).floor
	}
	geomP {
		^this.unifGeomP(0.0.rrand(1.0))
	}
	//This is the p-param of a 0-indexed geometric RV
	unifGeomM {arg unif;
		^(unif.log/((this/(1+this)).log)).floor;
	}
	geomM {
		^this.unifGeomM(0.0.rrand(1.0))
	}
	//This is the beta-param of a 0-indexed geometric RV
	unifExpS {arg unif;
		^unif.log.neg*this
	}
	expS {
		^this.unifExpS(0.0.rrand(1.0))
	}
	//This is the lambda-param of a 0-indexed geometric RV
	unifExpR {arg unif;
		^unif.log.neg/this
	}
	expR {
		^this.unifExpR(0.0.rrand(1.0))
	}
	
	
}