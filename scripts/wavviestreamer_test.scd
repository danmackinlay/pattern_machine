Pattern
Stream
EventStreamPlayer
q=1.asQuant
q.quant;
Pfunc
PRoutine
Spawner
Pbind(
	\degree, Pseq([1,2,3],2)
).collect({|in| in.postcs;}).play;
(
fork {
	p=PSWavvieStreamer.new(
	parentEvent: (degree: 0, stuff: \nonsense),
	state: (things: \toremember),
	notecallback: {|ev, seq| [seq.clock.beats, ev, seq].postcs; ev;},
	debug: false);
	p.play;
	3.wait;
	t=p.add(Pbind(\degree, Pseq([1,2,3],2)));
}
)
