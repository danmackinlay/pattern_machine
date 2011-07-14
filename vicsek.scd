v=VicsekGrid.new(population:2, noise: 0.1, delta: 0.01, radius: 0.1, dim:3, tickTime:0.1);
~out = Bus.new(\audio, 2, 4);
v.radius=0.1;
v.start;
v.play(s, bus: ~out);
v.noise_(0);
v.particles.collect({|i| i.vel});
v.bus;
v.free;
v.particles[0].synth
{Out.ar(2, PanAz.ar(4, Saw.ar(220), 1.25))}.play
