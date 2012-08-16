Server.default = s = ~serverboot.(\local, \internal);
//Server.default = s = ~serverboot.(\local, \motu);
//Server.default = s = ~serverboot.(\internal, \motu);

~wheremyfuckingipadis = NetAddr("192.168.0.7", NetAddr.langPort)
~localfuckingosculator = NetAddr("localhost", 7668)
//OSCFunc.newMatching({|...ar| ar.postln;}, "/", ~wheremyfuckingipadis);
OSCdef.newMatching(\fader1,{|...ar| ar.postln;}, "/1/fader1", ~localfuckingosculator);
//OSCFunc.new({|...ar| ar.postln;}, "/", ~localfuckingosculator);
//OSCFunc.trace(true);
//OSCFunc.trace(false);
// poly_ _lfo -style
~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~inbus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\inbus, ~inbus, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite_lfo, [\outbus	, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));

SynthDef.new(\autorecorder, {|inbus, sndbuffer, pitchbuffer, ampthresh=0.1, certthresh=0.9, duration=10|
	var recordtrig, haspitch, pitch, currsndbuffer, currpitchbuffer, onset;
	//TODO implement many buffers with Stepper.kr and Latch.kr
	currsndbuffer = sndbuffer;
	currpitchbuffer = sndbuffer;
	inbus = In.ar(inbus);
	# pitch, haspitch = Tartini.kr(inbus);
	haspitch.poll(10, \p);
	//onset = Coyote.kr(inbus);
	recordtrig = Trig.kr((haspitch>certthresh), dur: duration);
	recordtrig.poll(10, \rt);
	RecordBuf.ar(inbus, run: recordtrig, trigger: recordtrig, loop:0);
}).add;
//~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~recBuf = Buffer.new(numFrames: s.sampleRate*10.0, numChannels:1);
~inbus = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~recorder = Synth.new(\autorecorder, [\inbus, ~inbus, \sndbuffer,  ~recBuf, \duration, 10]);
~recBuf.plot;
/*
 * TODO:
 * * maybe spectrally extract output from input?
 * * or just work out if there is truly a difference by MFCC
 * * record many buffers
 * * provide smart recommendations of volume threshold, poss via GUI.
 * * Dfsm+DiWhite+TGrains for fun granualtions
 */