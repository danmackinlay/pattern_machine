//TODO: use JITLib to make this compile nicely
//TODO: turn this into an instrument with nice intuitive GUI controls etc.

~globalOuts = Bus.new(\audio, 0, 4);
~voxGroup = Group.new(s);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);
s.volume.volume= -20;

~sourceIns = Bus.audio(s, 2);
//read hardware in at head of ~voxGroup
~inVox={ SoundIn.ar([0, 1]) }.play(target:~voxGroup, outbus:~sourceIns);
~glim = GlimmerFilter.new;
//~glim = ListeningGlimmerFilter.new;
~glim.play(out:~globalOuts, in:~sourceIns, fxGroup: ~fxGroup);
~glim.freqs = [390, 335];
~glim.outbus;
~glim.inbus;
~glim.server;
~glim.freqBuf;
~glim.ratioBuf;
~glim.freqBufPointer.get(_.postln);
~glim.fxgroup;
~glim.fxsynth;
~glim.listensynth;
~glim.listengroup;

//s.volume.gui;

~glim.freqBufPointer.get(_.postln);
~glim.freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});

