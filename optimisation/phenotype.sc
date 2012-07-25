PSPhenotype {
	var <chromosome;
	var <>fitness=0;
	var <logicalAge=0;
	var <birthTime;

	*new{|chromosome|
		var noob = super.new;
		noob.chromosome = chromosome;
		^noob
	}
	*newRandom {|initialChromosomeSize|
		^this.new(this.randomChromosome(initialChromosomeSize));
	}
	*randomChromosome{|initialChromosomeSize|
		//This should really be attached to the chromosome class
		^{1.0.rand;}.dup(initialChromosomeSize);
	}
	chromosome_ {|newChromosome|
		//don't just copy a ref- each phenotype gets its own copy.
		chromosome = Array.newFrom(newChromosome);
	}
	clockOn {
		birthTime = Date.gmtime.rawSeconds;
	}
	wallClockAge {
		birthTime.isNil.if({^0.0}, {
			^Date.gmtime.rawSeconds - birthTime;
		});
	}
	incAge {
		//increments logical (iteration count) age
		logicalAge = logicalAge +1;
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" << chromosome << ")";
	}
}
