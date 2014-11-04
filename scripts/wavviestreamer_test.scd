Pbind(
	\degree, Pseq([1,2,3],2)
).collect({|in| in.postcs;}).play;
(
fork {
	p=PSStreamer.new(
		state: (things: \toremember),
		//notecallback: {|ev, seq| [seq.clock.beats, ev, seq].postcs; ev;},
		debug: true);
	p.play(trace:true);
	3.wait;
	t=p.add(Pbind(\degree, 1, \delta, 1), id: \a);
	t=p.add(Pbind(\degree, 5, \delta, 1), id: \b, delta: 0.5);
}
)
(
fork {
	p=PSStreamer.new(
		state: (things: \toremember),
		notecallback: {|ev, seq| ev.degree=5.rand;[seq.clock.beats, ev, seq].postcs; ev;},
		debug: true);
	p.play(trace:true, evt: (degree: 0, stuff: \nonsense));
	3.wait;
	t=p.add(Pbind(\degree, 0));
}
)
p.masterQuant

p.clock.beats
p.asEventStreamPlayer
