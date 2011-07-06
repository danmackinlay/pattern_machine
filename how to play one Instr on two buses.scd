///Note- this doesn't work! ~src will get spawned once for each.grou

//Mono version
(
//create a Bus for Instrs to play on
~privateOut = Bus.audio(s,1);
//create a bus for the master outs
~publicOut = Bus.new(\audio, 0,1);
//create a instr to play
~src = Patch({Saw.ar(300).poll;}).play(bus:~privateOut);
//Now, some FX so we can hear the difference.
//put fx in group after the default one.
~fxGroup = Group.new(addAction: \addAfter);
//listen to the high tone
~fx1 = Patch({|in| Resonz.ar(in, 900, 0.01);}, [~src]).play(group:~fxGroup);
//listen to the lower tone
~fx2 = Patch({|in| Resonz.ar(in, 700, 0.005);}, [~src]).play(group:~fxGroup);
//and we even get the unfiltered version if we want
~privateOut.play();
//Here's what happened with the bus assignment
["src", ~src.bus].postln;
["fx1", ~fx1.bus].postln;
["fx2", ~fx2.bus].postln;
["privateout", ~privateOut].postln;
)

//Now, let's try that multichannel.
(
~privateOut = Bus.audio(s,4);
~publicOut = Bus.new(\audio, 0, 4);
~src = Patch({Pan4.ar(Saw.ar(300), SinOsc.ar(1), SinOsc.ar(1, pi/2),1);}).play(bus:~privateOut);
~fxGroup = Group.new(addAction: \addAfter);
~fx1 = Patch({|in| Resonz.ar(in, 900, 0.01);}, [~src]).play(group:~fxGroup);
~fx2 = Patch({|in| Resonz.ar(in, 700, 0.005);}, [~src]).play(group:~fxGroup);
~privateOut.play();
["src", ~src.bus].postln;
["fx1", ~fx1.bus].postln;
["fx2", ~fx2.bus].postln;
["privateout", ~privateOut].postln;
)
