v=VicsekGrid.new(population:60, noise: 0.0, delta: 0.1, radius: 0.5, dim:2, tickTime:1);
v.start;
v.particles.collect({|i| i.vel});