VicsekParticle {
	/*hold particle location and heading, and enforce boundary contraints.
	updating etc is handled by the wrapping VicsekGrid class*/
	var dim, <pos, <vel;
	*new {|pos, vel, dim=2|
		^super.newCopyArgs(dim).pos_(pos).vel_(vel);
	}
	pos_ {|posArray|
		posArray.isNil.if(
			{pos = RealVector.rand(dim)},
			{
				//["wrapping to", posArray.wrap(0,1)].postln;
				pos = RealVector.newFrom(posArray.wrap(0,1));}
		)
	}
	vel_{|velArray|
		velArray.isNil.if(
			{vel=VicsekGrid.randomVector(dim);},
			{vel=RealVector.newFrom(velArray);}
		);
		vel = vel/vel.norm;
	}
	free {
		
	}
}
VicsekGrid {
	var <>population, <>noise, <>delta, <>radius, <dim, <tickTime, <clock, <ticker, <particles;
	classvar normRng;
	
	*new {|population, noise, delta, radius, dim=2, tickTime=1|
		^super.newCopyArgs(population, noise, delta, radius, dim, tickTime).init; 
	}
	init {
		particles = population.collect({VicsekParticle.new;});
	}
	start {
		clock = TempoClock.new(tickTime.reciprocal, 1);
		ticker = Task.new({loop {this.tick; 1.wait;}}, clock);
		ticker.start;
	}
	stop {
		ticker.stop;
	}
	tick {
		var tempVels = population.collect({this.class.nullVector(dim);});
		//move
		particles.do({|particle, idx|
			//["shunting particle", particle.pos, "by", particle.vel*delta].postln;
			particle.pos = particle.pos+(particle.vel*delta);
			//["shunted particle", particle.pos].postln;
		});
		//aggregate
		(0..(population-2)).do({|i|
			(1..(population-1)).do({|j|
				var a, b;
				a=particles[i];
				b=particles[j];
				//["updatingneighbourhoods", i, j, tempVels[i], tempVels[j]].postln;
				((a.pos-b.pos).norm<radius).if({
					tempVels[i] = tempVels[i] + b.vel;
					tempVels[j] = tempVels[j] + a.vel;
					//["updated", tempVels[i]].postln;
				});
			});
		});
		particles.do({|particle, i|
			particle.vel_(tempVels[i]);
			//["vel now", particle.vel].postln;
		});
		//randomise?
		// this.class.randomVector(dim)
	}
	free {
		particles.do({|particle| particle.free;});
	}
	*randomVector {|nDim=2|
		//un-normalised vector with angle equidistribution.
		normRng.isNil.if({normRng = Pgauss(0.0, 1, inf).asStream});
		^RealVector.newFrom(normRng.nextN(nDim));
	}
	*nullVector {|nDim=2|
		^RealVector.newFrom(0.dup(nDim));
	}
}
