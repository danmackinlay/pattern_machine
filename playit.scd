s=~serverboot.(prox:\local, device:\internal);
ServerOptions.inDevices;
~here = "/Users/dan/src/python/arpeggiate_by_numbers";

~square={|x,c=0,d=0.125| ((x-c).abs<d).binaryValue};
~b0=~square.value(_,0);
~b1=~square.value(_,0.5);
~b2=~square.value(_,1.0);
~fns=[~b0, ~b1, ~b2];
~fns.collect({|fn| fn.value(1)});
~fns.collect({|fn| fn.value(FloatArray.series(10,0,0.0625))});

~squareA={|x,c=0,d=0.125|
	x.isCollection.if(
		{((x-c).abs<d).collect(_.binaryValue)},
		{((x-c).abs<d).binaryValue})
};
~b0A=~squareA.value(_,0);
~b1A=~squareA.value(_,0.5);
~b2A=~squareA.value(_,1);
~fnsA=[~b0A, ~b1A, ~b2A];
~fns.collect({|fn| fn.value(1)});
~fnsA.collect({|fn| fn.value(FloatArray.series(10,0,0.0625))});

~notelm.value(i:5, nState:[0,0,0,0,0,0,0,1,0,0,0,0,0]);
20.collect(~notelm.value(_,[0,0,0,0,0,0,0,1,0,0,0,0,0]));
~n=Noteomata.new;
~n.nextOnProbs;
~n.add(46);
~n.add(47);
~n.add(48);
~n.add(51);
~n.nextOnProbs.do({|v,i| [i,v].postln;});
~n.nextOnProbs.plot;
~n.pushOn;
~n.heldNotes;
~n.step(0.2);
(
~n=Noteomata.new(window:2, defaultNote:48, maxJump:7);
~state = (\n: ~n);
~innotes = Pbind(
	\delta, Prand([0,0,1/4,1/8,1/3],16)
).collect(
	{|in|
		in.asCompileString.postln;
		in['midinote']=~state[\n].pushOn;
		~state[\n].step(in.delta);
		{~state[\n].nextOnProbs.plot}.defer;
		in;
	}
).collect(_.postln).play();
)
(
~n.heldNotes;
)
//Storing state? See Pattern Guide 06g
MIDIClient.init;    // if not already done


/*
The \midi event type supports the following commands, chosen in the event by the \midicmd key: \allNotesOff, \bend, \control, \noteOff, \noteOn, \polyTouch, \program, \smpte, \songPtr, \sysex, \touch. The default is \noteOn. When playing a note (noteOn), by default the corresponding noteOff message will be sent after the note's sustain time.
*/
(
    // substitute your own device here
var    mOut = MIDIOut.newByName("FastLane USB", "Port A").latency_(Server.default.latency);

p = Pbind(
    \type, \midi,
        // this line is optional b/c noteOn is the default
        // just making it explicit here
    \midicmd, \noteOn,
    \midiout, mOut,    // must provide the MIDI target here
    \chan, 0,
        // degree is converted to midinote, not just frequency
    \degree, Pwhite(-7, 12, inf),
    \dur, Pwrand([0.25, Pn(0.125, 2)], #[0.8, 0.2], inf),
    \legato, sin(Ptime(inf) * 0.5).linexp(-1, 1, 1/3, 3),
    \amp, Pexprand(0.5, 1.0, inf)
).play(quant: 1);
)

p.stop;