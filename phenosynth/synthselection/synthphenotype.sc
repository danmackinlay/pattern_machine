PSSynthDefPhenotype : PSPhenotype {
	//A phenotype connecting a chromosome to the inputs of a SynthDef
	classvar <defaultSynthDef = \ps_reson_saw;
	classvar <defaultSynthArgMap;
	
	var <>synthDef;
	var <>synthArgMap;
	
	*new {|chromosome, synthDef, synthArgMap|
		//default to class's synthDef and synthArgMap to make trivial subclasses easy.
		var noob = super.new(chromosome);
		noob.synthDef = synthDef ? defaultSynthDef;
		noob.synthArgMap = synthArgMap ? defaultSynthArgMap;
		^noob;
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
		playsynthdefs file. Subclasses might do otherwise.*/
	}
	*setUpMappingToSynthDef {
		//defaultSynthArgMap as befits defaultSynth
		//feels like it should be declared in the class proper, but needs to
		//wait until init time.
		defaultSynthArgMap = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec,
			\gain: \unipolar.asSpec
		);
	}
	*chromosomeAsSynthArgs {|chrom, synthArgMap|
		/*Zip together the key, synthArgMap spec and value lists into one, then
		iterate over this, returning synthArgMapped values associated with their
		keys as a synth expects
		
		NB - this is always sorted by argument name, and, at the moment,
		only supports float scalar values.*/

		var synthArgMapArray;
		synthArgMap = (synthArgMap ? defaultSynthArgMap);
		synthArgMapArray = synthArgMap.asSortedArray;
		^synthArgMapArray.size.collect({|i|
			[synthArgMapArray[i][0], 
			  synthArgMapArray[i][1].map(chrom.at(i))
			]
		}).flat;
	}
	*synthArgsAsChromosome {|synthArgs, synthArgMap|
		/*
		NB - this is always sorted by argument name, and, at the moment,
		only supports float scalar values
		*/
		var chromosome, synthArgMapArray;
		chromosome = List.new;
		synthArgMap = (synthArgMap ? defaultSynthArgMap);
		//this step looks redundant, but keeps ordering well-defined.
		synthArgMapArray = synthArgMap.asSortedArray;
		synthArgs.pairsDo({|k,v|
			chromosome.add(synthArgMap[k].unmap(v));
		});
		^chromosome.asArray;
	}
	chromosomeAsSynthArgs {
		/*Zip together the key, synthArgMap spec and value lists into one, then
		iterate over this, returning synthArgMapped values associated with their
		keys as a synth expects*/
		^this.class.chromosomeAsSynthArgs(chromosome, synthArgMap);
	}
}

PSSynthPhenotype : PSSynthDefPhenotype {
	/* Hold a particular synth *instance* and associate fitness with it.
	I'm not sure this merits a distinct subclass, or that the single method it has is not
	better associated with a PS*Controller. */
	
	stop {|synth|
		synth.set(\gate, 0);
	}
}