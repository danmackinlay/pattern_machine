MCPhenosynthIndividual : GAIndividual {
	mate { arg partner, pcrossover, pdelete, pmutate, pduplicate; // "partner" should be another GAIndividual
		^super.mate(partner: partner, 
			pcrossover:pcrossover,
			pdelete: 0,
			pmutate: pmutate,
			pduplicate: 0
		);
	} // End of mate method

	calculatePhenome {
		// Phenome is a STRING which will be wrapped in "{|t_trig=0|" and "}", then interpreted.
		// Override this in subclasses to create whatever is desired, based on the genome values
		var g = this.genome;
		^"SinOsc.ar("++\freq.asSpec.map(g[0]).asString++")*0.1;";
	}
} // End of class