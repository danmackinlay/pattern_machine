PSPhenotype {
	var <chromosome;
	var <>fitness=0;
	var <logicalAge=0;
	var <birthTime;
	
	classvar <>genomeSize = 3;
	
	*new{|chromosome|
		^super.new.init(chromosome);
	}
	*newRandom {|forceGenomeSize|
		var newChromosome = {1.0.rand;}.dup(forceGenomeSize ? genomeSize);
		^this.new(newChromosome);
	}
	init {|chromosome|
		//don't just copy a ref- each phenotype gets its own copy.
		this.chromosome = Array.newFrom(chromosome);
	}
	chromosome_ {|newChromosome|
		chromosome = newChromosome;
	}
	play {|out|
		NotYetImplementedError.new.throw;
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
		//incremenets logical (iteration count) age
		logicalAge = logicalAge +1;
	}
	printOn { arg stream;
		stream << this.class.asString <<"(" << chromosome << ")";
	}
}
