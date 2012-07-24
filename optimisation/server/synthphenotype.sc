PSSynthDefPhenotype : PSPhenotype {
	//A phenotype connecting a chromosome to the inputs of a SynthDef
	classvar <defaultSynthDef = \ps_reson_saw;
	classvar <defaultSynthArgMap;

	var <>synthDef;
	var <>synthArgMap;

	*new {|chromosome, synthDef, synthArgMap|
		//default to class's synthDef and synthArgMap to make trivial subclasses easy.
		//although if you are subclassing you might want to use a Factory
		var noob = super.new(chromosome);
		noob.synthDef = synthDef ? defaultSynthDef;
		noob.synthArgMap = synthArgMap ? PSBasicPlaySynths.synthArgMaps[noob.synthDef];
		^noob;
	}

	*newFromSynthArgs {|synthArgs, synthDef, synthArgMap|
		var chromosome;
		synthDef = synthDef ? defaultSynthDef;
		synthArgMap = synthArgMap ? defaultSynthArgMap;
		chromosome = this.synthArgsAsChromosome(synthArgs, synthArgMap);
		^this.new(chromosome, synthDef, synthArgMap)
	}

	*initClass {
		StartUp.add {
			defaultSynthArgMap = (
				\pitch: \midfreq.asSpec,
				\ffreq: \midfreq.asSpec,
				\rq: \rq.asSpec,
				\gain: \unipolar.asSpec
			);
		};
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

PSSynthDefPhenotypeFactory {
	/*
	A handy class that you can pass in as the individualFactory parameter to allow
	class-free synth phenotype implementation.

	You shouldn't have to subclass things just to override a trivial parameter or two.
	*/
	classvar <>defaultPhenotypeClass;

	var <synthDef;
	var <synthArgMap;
	var <phenotypeClass;

	*new {|synthDef, synthArgMap, phenotypeClass|
		synthDef = synthDef ? PSSynthDefPhenotype.defaultSynthDef;
		^super.newCopyArgs(
			synthDef,
			synthArgMap ? PSBasicPlaySynths.synthArgMaps[synthDef],
			phenotypeClass ? defaultPhenotypeClass
		);
	}

	*initClass {
		StartUp.add {
			defaultPhenotypeClass = PSSynthDefPhenotype;
		};
	}

	new {|chromosome|
		^phenotypeClass.new(chromosome, synthDef, synthArgMap);
	}

	newRandom {|initialChromosomeSize|
		^this.new(phenotypeClass.randomChromosome(initialChromosomeSize));
	}

	newFromSynthArgs {|synthArgs|
		var chromosome;
		chromosome = phenotypeClass.synthArgsAsChromosome(synthArgs, synthArgMap);
		^this.new(chromosome);
	}
}
