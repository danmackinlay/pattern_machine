v=VicsekGrid.new(population:60, noise: 0.1, delta: 0.05, radius: 0.5, dim:3, tickTime:0.1);
~out = Bus.new(\audio, 0, 4);
v.start;
v.play(s, bus: ~out);
v.particles.collect({|i| i.vel});
v.bus;
v.particles[0].synth
