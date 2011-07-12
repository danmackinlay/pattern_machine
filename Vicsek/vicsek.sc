VicsekParticle {
	/*hold particle location and heading, and enforce boundary contraints.
	updating etc is handled by the wrapping VicsekGrid class*/
	var dim, <pos, <vel;
	classvar rng;
	*new {|pos, vel, dim=2|
		^super.newCopyArgs(dim).pos_(pos).vel_(vel);
	}
	*randomVector {|dim=2|
		//un-normalised vector with angle equidistribution.
		rng.isNil.if({rng = Pgauss(0.0, 1, inf).asStream});
		^RealVector.newFrom(rng.nextN(dim));
	}
	pos_ {|posArray|
		posArray.isNil.if(
			{pos = RealVector.rand(dim)},
			{pos = RealVector.newFrom(posArray.wrap(0,1));}
		)
	}
	vel_{|velArray|
		velArray.isNil.if(
			{vel=this.class.randomVector;},
			{vel=RealVector.newFrom(velArray);}
		);
		vel = vel/vel.norm;
	}
	free {
		
	}
}
VicsekGrid {
	var <>population, <>noise, <>delta, <>radius, <>tickTime, <clock, <ticker, <particles;
	*new {|population, noise, delta, radius, tickTime=1|
		^super.newCopyArgs(population, noise, delta, radius, tickTime).init; 
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
		particles.do({|particle, idx|
			["shunting particle", particle.pos, "by", particle.vel*delta].postln;
			particle.pos = particle.pos+(particle.vel*delta);
			["shunted particle", particle.pos].postln;
		});
	}
	free {
		particles.do({|particle| particle.free;});
	}
}
