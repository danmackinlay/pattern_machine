//TODO: use JITLib to make this compile nicely
//TODO: turn this into an instrument with nice intuitive GUI controls etc.

~globalOuts = Bus.new(\audio, 0, 4);
~voxGroup = Group.new(s);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);

~sourceIns = Bus.audio(s, 2);
//read hardware in at head of ~voxGroup
~inVox={ SoundIn.ar([0, 1]) }.play(target:~voxGroup, outbus:~sourceIns);
~glim = GlimmerFilter.new
~glim.play(out:~globalOuts, in:~sourceIns, fxGroup: ~fxGroup);

~glim.outbus;
~glim.inbus;
~glim.glimmerTracker;
~glim.server;
~glim.freqBuf;
~glim.ratioBuf;
~glim.freqBufPointer;
~glim.listengroup;
~glim.fxgroup;
~glim.listensynth;
~glim.fxsynth;

//s.volume.gui;
s.volume.volume= -20;

~freqBufPointer.get(_.postln);
~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});