//So I'm writing frequencies detected using Pitch to a Buffer. These frequencies are clamped to the defaut Pitch range of [100, 4000]. But when i write 'em to the buffer, i get mysterious random numbers appearing which are not in that range. The problem occurs in my fresh build of SC 3.5, but not 3.4. I wonder if something about how you write to buffers has changed between versions and I'm getting it wrong, or if there is a bug here I should report.

//Example:

SynthDef.new(\findfreqs, {|in, rate = 10, gate=1, freqBuf, freqBufPointer|
	var hasFreq, freq, index, writing=0;
	rate = rate.min(ControlRate.ir/2);//so triggers work
	//we presume freqBuf has 513 samples, and use 512, writing to th 513th when there is no freq detected
	#freq, hasFreq = Pitch.kr(In.ar(in), execFreq: rate);
	writing = hasFreq* gate;
	index = Stepper.kr(Impulse.kr(rate) * writing, max: 511);
	index = (index+(512*(1-writing))).min(512);  //this last bit moves the read head to the end when there is no freq. Maybe I should do this at demand rate instead?
	freq.poll(10, \written);
	BufWr.kr(
		inputArray: freq,
		bufnum: freqBuf,
		phase: index
	);
	Out.kr(freqBufPointer, Gate.kr(index, hasFreq));
}).send(s);

SynthDef.new(\hardwarein,
	{|in, out|
		in = SoundIn.ar(in);
		// Amplitude.kr(in, releaseTime:1).poll(1, \inamp);
		Out.ar(out, in);}
).send(s);

~freqBuf = Buffer(s, 513, 1);
//pitches all 440Hz by default
s.listSendMsg( ~freqBuf.allocMsg( ~freqBuf.setnMsg(0, 440!513) ).postln );

~globalOuts = Bus.new(\audio, 0, 2);
~freqBufPointer = Bus.control(s, 1);
~sourceIns = Bus.audio(s, 1);
~voxGroup = Group.new(s);
~fxGroup = Group.after(~voxGroup);
~outGroup = Group.after(~fxGroup);
//read hardware in at head of ~voxGroup
~inVox = Synth(\hardwarein, [\in, 0, \out, ~sourceIns], ~voxGroup);
~listener = Synth.head(~fxGroup, \findfreqs, [\in, ~sourceIns, \freqBuf, ~freqBuf, \freqBufPointer, ~freqBufPointer]);
~freqBufPointer.get(_.postln);

Run al that, then play some tonal input to the system so that the ~freqBuf fills up.

Now, on a supercollider 3.4 build this works OK:

~freqBuf.loadToFloatArray(count: -1, action: {|arr| arr.postln;});

Buffer(4, 513, 1, 44100, nil)
FloatArray[ 318.60125732422, 103.28491210938, 60.89527130127, 137.85426330566, 129.94828796387, 218.09902954102, 229.84844970703, 229.84844970703, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, ...etc...

However, if i use my fresh build of SC 3.5 from the repository, weird things happen:

Buffer(0, 513, 1, 44100, nil)
FloatArray[ 137.87020874023, 124.47654724121, 122.73538970947, 148.74942016602, 0, 1.9028314803936e-37, 247452434432, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440, 440,...etc...


0?
1.9028314803936e-37?
247452434432?

Honestly, i swear i can't sing any of those frequencies.

So, bug, or idiocy on my part?

-dan
