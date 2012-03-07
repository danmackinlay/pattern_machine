PSPhenotype {
	classvar <counter=0;
	
	var <idx;
	var <chromosome;
	var <>fitness=0;
	var <logicalAge=0;
	var <birthTime;
		
	*new{|chromosome|
		^super.newCopyArgs(counter).init(chromosome);
	}
	*newRandom {|initialChromosomeSize|
		var newChromosome = {1.0.rand;}.dup(initialChromosomeSize);
		^this.new(newChromosome);
	}
	init {|newChromosome|
		//make sure chromosome access goes through *our* setter.
		this.chromosome = newChromosome;
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
