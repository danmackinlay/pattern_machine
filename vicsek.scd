v=VicsekGrid.new(population:10, noise: 0.1, delta: 0.01, radius: 0.1, dim:3, tickTime:0.1);
~out = Bus.new(\audio, 0, 4);
v.radius=0.1;
v.start;
v.play(s, bus: ~out);
v.particles.collect({|i| i.vel});
v.bus;
v.free;
v.particles[0].synth
