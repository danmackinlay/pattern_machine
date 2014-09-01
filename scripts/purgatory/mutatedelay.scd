s=Dan.serverboot(prox:\local, device:\rme);
s=Dan.serverboot(prox:\local, device:\internal);
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Routing-audio-synths-using-ProxySpace-td6416833.html"
// "http://comments.gmane.org/gmane.comp.audio.supercollider.user/65142"
// "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/JITLib-basics-td6990590.html"
(
var state = ();
~state=state;
fork {state.make({
	~c1x1=SynthDef.new(\ps_mutatingreverb_4__1x1,
		diffuserfactory.value(
			{|in|[In.ar(in,1)]},
			{|chan, i| chan.sum},
			outchan:1,
		)
	).add;
	~c1x2=SynthDef.new(\ps_mutatingreverb_4__1x2,
		diffuserfactory.value(
			{|in|[In.ar(in,1)]},
			{|chan, i|
				//chan.poll(5,\flarg1, i);
				Splay.ar(chan)},
			outchan:2,
		)
	).add;
	~c2x2=SynthDef.new(\ps_mutatingreverb_4__2x2,
		diffuserfactory.value(
			{|in|In.ar(in,2)},
			{|chan, i|
				//chan.poll(5, \flarg2, i);
				Splay.ar(chan, spread: 1-(2*i))},
			outchan:2,
		)
	).add;
	~testsamplepath = PS.scsamplepath +/+ "NS-wind-chimes-002-denoise-edit.wav";
	~testbuf=Buffer.read(s, ~testsamplepath);
	~outbus = Bus.new(\audio, 0, 2, s);
	s.sync;
	~testsound = Synth.head(
		s,
		\playbuf__1x2, [
			\out, ~outbus.subBus(0,1),
			\bufnum, ~testbuf
		]
	);
	~reverb = Synth.tail(
		s,
		\ps_mutatingreverb_4__1x2, [
			\in, ~outbus.subBus(0,1),
			\out, ~outbus,
			\delay, 0.3,
			\delayvar, 1,
			\gain, 1,
			\dry, 0,
		]
	);
})};
)
~state.c1x1.dumpUGens;
~state.c1x2.dumpUGens;
~state.c2x2.dumpUGens;
