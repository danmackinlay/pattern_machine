Server.default = s = ~serverboot.(\local, \motu);
//Server.default = s = ~serverboot.(\internal, \motu);

~wheremyfuckingipadis = NetAddr("192.168.0.7", NetAddr.langPort)
~localfuckingosculator = NetAddr("localhost", 7668)
//OSCFunc.newMatching({|...ar| ar.postln;}, "/", ~wheremyfuckingipadis);
OSCdef.newMatching(\fader1,{|Éar| ar.postln;}, "/1/fader1", ~localfuckingosculator);
//OSCFunc.new({|...ar| ar.postln;}, "/", ~localfuckingosculator);
//OSCFunc.trace(true);
//OSCFunc.trace(false);
// poly_ _lfo -style
~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite_lfo, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));
