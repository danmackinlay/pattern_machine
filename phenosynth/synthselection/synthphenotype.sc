PSSynthDefPhenotype : PSPhenotype {
	//A phenotype mapping a chromosome to the inputs of a SynthDef
	classvar <synthdef = \ps_reson_saw;
	classvar <map;
	
	var <mappedArgs;
	
	*genomeSize {
		^map.size;
	}
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
		/*This list comprehension is not especially clear now, is it?
		What it does is zip together the key, map spec and value 
		lists into one, then iterates over this, returning mapped values
		associated with their keys as a synth expects*/
		^(all {: [keySpecVal[0], keySpecVal[1].map(keySpecVal[2])],
			keySpecVal <- (this.class.map.asSortedArray +++ chromosome)
		}).flat;
	}
}
	

PSSynthPhenotype : PSSynthDefPhenotype {
	/* Hold a particular synth *instance* and associate fitness with it.
	I'm not sure this merits a distinct subclass. */
	
//	var <>lifeSpan = 20;
	
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