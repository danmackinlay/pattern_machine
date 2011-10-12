//TODO: use JITLib to make this compile nicely
//TODO: turn this into an instrument with nice intuitive GUI controls etc.

~globalOuts = Bus.new(\audio, 0, 4);
~voxGroup = Group.new(s);
~sourceIns = Bus.audio(s, 2);
~inVox={ SoundIn.ar([0, 1]) }.play(target:~voxGroup, outbus:~sourceIns);
~glim = GlimmerFilter.new(~globalOuts, ~sourceIns);

~freqBuf = Buffer(s, 513, 1);
~ratioBuf = Buffer(s, 512, 1);
// alloc and set the values
//pitches all 440Hz by default
s.listSendMsg( ~freqBuf.allocMsg( ~freqBuf.setnMsg(0, 440!513) ).postln );
//ratios all 1 by default.
s.listSendMsg( ~ratioBuf.allocMsg( ~ratioBuf.setnMsg(0, 1!513) ).postln );
//Now..
~globalOuts = Bus.new(\audio, 0, 4);
~freqBufPointer = Bus.control(s, 1);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);
//read hardware in at head of ~voxGroup
//s.volume.gui;
s.volume.volume= -20;
~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
~fx = Synth.tail(~fxGroup, \glimmergrains, [\in, ~sourceIns, \out, ~globalOuts, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer, \numBuf, ~ratioBuf, \trigRate, 1, \wideness, 1]);
~freqBufPointer.get(_.postln);
~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});