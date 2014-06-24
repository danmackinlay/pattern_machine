PSParkingSun {
	*home {
		^this.filenameSymbol.asString.dirname.dirname;
	}
	*scripts {
		^this.home +/+ "scripts";
	}
}