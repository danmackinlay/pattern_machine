PSPhenotype {
	var <chromosome;
	var <>fitness=0;
	var <logicalAge=0;
	var <birthTime;
	
	classvar <genomeSize = 3;
	
	*new{|chromosome|
		^super.new.init(chromosome);
	}
	*newRandom {
		var newChromosome = {1.0.rand;}.dup(genomeSize);
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
	printOn { arg stream;
		stream << this.class.asString <<"(" << chromosome << ")";
	}
}

PSSynthDefPhenotype : PSPhenotype {
	//A phenotype mapping a chromosome to the inputs of a Synth
	classvar <synthdef = \ps_reson_saw;
	classvar <map;
	classvar <synth; //mixed feeling about letting phenosynths hold a reference to their own synth
	var <mappedArgs;
	*initClass {
		StartUp.add {
			this.setUpSynthDefs;
		}
	}
	*setUpSynthDefs {
		SynthDef.new(
			\ps_reson_saw,
			{|out=0, gate=0, t_reset=0, pitch, ffreq, rq|
				var env;
				var time = 1;
				env = EnvGen.kr(
					Env.asr(time/2, 1, time/2, 'linear'),
					gate: gate,
					doneAction: 2
				);
				Out.ar(out, Resonz.ar(
					Saw.ar(pitch),
						ffreq,	 //cutoff
						rq			 //inverse bandwidth
					)*env
				);
			}
		).add;
		map = (
			\pitch: \midfreq.asSpec,
			\ffreq: \midfreq.asSpec,
			\rq: \rq.asSpec
		);
	}
	play {|out, group|
		mappedArgs = this.chromosomeAsSynthArgs;
		synth = Synth.new(
			this.class.synthdef,
			args: [\out, out, \gate, 1] ++ mappedArgs,
			target: group
		)
		^synth;
	}
	free {
		synth.set(\gate, 0);
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
	
