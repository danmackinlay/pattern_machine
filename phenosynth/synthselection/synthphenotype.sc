PSSynthDefPhenotype : PSPhenotype {
	//A phenotype mapping a chromosome to the inputs of a SynthDef
	classvar <synthdef = \ps_reson_saw;
	classvar <map;
	
	var <mappedArgs;
	
	*initClass {
		StartUp.add {
			this.setUpSynthDefs;
		};
		StartUp.add {
			this.setUpMappingToSynthDef;
		};
	}
	*setUpSynthDefs {
		/*Nothing to do here;  I just use the generic \ps_reson_saw in the
		playsynthdefs file. Subclasses might be otherwise.*/
	}
	*setUpMappingToSynthDef {	
		map = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec,
			\gain: \unipolar.asSpec
		);
	}
	chromosomeAsSynthArgs {
		/*Zip together the key, map spec and value lists into one, then
		iterate over this, returning mapped values associated with their
		keys as a synth expects*/
		var maparray = this.class.map.asSortedArray;
		^this.class.map.size.collect({|i|
			[maparray[i][0], 
			  maparray[i][1].map(chromosome.at(i))
			]
		}).flat;
	}
}

PSSynthPhenotype : PSSynthDefPhenotype {
	/* Hold a particular synth *instance* and associate fitness with it.
	I'm not sure this merits a distinct subclass. */
	
	stop {|synth|
		synth.set(\gate, 0);
	}
	fitness {
		//override fitness to cause aging in chromosomes
		//var ageNow = this.logicalAge;
		//^(fitness * ageNow / (ageNow.exp));
		^fitness;
	}
}