v=VicsekGrid.new(population:25, noise: 0.15, delta: 0.005, radius: 0.1, dim:3, tickTime:0.1, rescale: 2);
~out = Bus.new(\audio, 0, 4);
v.start;
v.play(s, bus: ~out, gain:0.1);
v.noise_(0);
v.particles.collect({|i| i.vel});
v.bus;
v.free;
{Out.ar(0, PanAz.ar(4, Saw.ar(220)*0.25, 1.75))}.play