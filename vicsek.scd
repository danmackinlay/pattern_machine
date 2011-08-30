v=VicsekGrid.new(population:15, noise: 0.4, delta: 0.005, radius: 0.1, dim:3, tickTime:0.1, rescale: 2);
~out = Bus.new(\audio, 0, 4);
v.start;
v.play(Server.internal, bus: ~out, gain:0.1);
v.outSynth.set(\gain,0.02);
v.noise;
v.clock.seconds
v.particles.collect({|i| i.vel});
v.bus;
v.free;
{Out.ar(0, PanAz.ar(4, Saw.ar(220)*0.25, 1.75))}.play
2pi