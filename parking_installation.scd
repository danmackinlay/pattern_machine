Server.default = s = ~serverboot.(\local, \internal);
//Server.default = s = ~serverboot.(\local, \motu);
Server.default = s = ~serverboot.(\internal, \motu);
Server.default = s = ~serverboot.(\internal, \internal);

~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite_lfo, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));
(
SynthDef.new(\autorecorder, {|in, sndbuffer, pitchbuffer, ampthresh=0.05, certthresh=0.9, duration=10|
	var recordtrig, amp, certainty, recordable, pitch, currsndbuffer, currpitchbuffer, onset;
	//TODO implement many buffers with Stepper.kr and Latch.kr
	currsndbuffer = sndbuffer;
	currpitchbuffer = sndbuffer;
	in = In.ar(in);
	# pitch, certainty = Tartini.kr(in);
	certainty.poll(1, \p);
	//onset = Coyote.kr(in);
	amp = Amplitude.kr(in);
	amp.poll(1, \a);
	recordable = (certainty>certthresh)*(amp>ampthresh);
	recordable.poll(1, \r);
	recordtrig = Trig1.kr(recordable, dur: duration);
	recordtrig.poll(1, \rt);
	RecordBuf.ar(in, run: recordtrig, trigger: recordtrig, loop:0);
}).add;
//~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~recBuf = Buffer.alloc(numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
)
(
~globalOuts = Bus.new(\audio, 0, 1);
~recorder = Synth.new(\autorecorder, [\in, ~in, \sndbuffer,  ~recBuf, \duration, 10]);
)
~recBuf.plot;
/*
 * TODO: 
 * * maybe spectrally extract output from input?
 * * or just work out if there is truly a difference by MFCC
 * * record many buffers
 * * provide smart recommendations of volume threshold, poss via GUI.
 * * Dfsm+DiWhite+TGrains for fun granualtions
 * * other fun instruments
 */