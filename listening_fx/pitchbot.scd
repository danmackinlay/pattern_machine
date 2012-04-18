Server.default = s = ~serverboot.(\local, \internal);
Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);
~input = Bus.newFrom(s.inputBus,0,1);
SynthDef(\ps_pitch_extractor, {
	|in, i_trigid, rate=20, thresh=0.9|
	var trig, gate, pitch, certainty;
	in = In.ar(in);
	trig = Impulse.kr(rate);
	#pitch, certainty = Tartini.kr(in);
	gate = certainty>thresh;
	SendTrig.kr(trig*gate, i_trigid, pitch);
}).add;
Synth.new(\ps_pitch_extractor, [\in, ~input, \i_trigid, 837]);
OSCdef.newMatching(\ps_pitch_extractor, func: {|msg,time,addr,recvPort| msg.postln;}, path:"/tr", argTemplate: [nil, 837]);