s=~serverboot.(prox:\local, device:\internal);
(
var analNode;
SynthDef.new(\transect12__1, {|inbuf=0,basef=220,outbuf,smoothness=8|
	var attackTime, delTimes, sig, inamp, refamps;
	//should individual bands have their own attack rates?
	//should we exploit diff attack and decays?
	attackTime=basef.reciprocal*smoothness;
	delTimes=Array.geom(12,basef.reciprocal,2**(-1.0/12.0));
	sig = PlayBuf.ar(
		numChannels:1,
		bufnum:inbuf,
		rate: BufRateScale.kr(inbuf),
		trigger: 1,
		loop: 0,
		doneAction: 2
	);
	inamp = Amplitude.ar(
		sig,
		attackTime:attackTime,
		releaseTime:attackTime,
	).max(0.0001);
	refamps = Amplitude.ar(
		DelayC.ar(sig, delaytime:delTimes) * sig,
		attackTime:attackTime,
		releaseTime:attackTime,
	).max(0.0001)/inamp;
	([inamp]++refamps).collect({|amp,i|
		DiskOut.ar(bus.asnum+i, amp)
	});
}).add;

fork {
	~infilep="/Users/dan/src/sc/f_lustre/sounds/note_sweep.aif";
	~outfilep=~pmscripts +/+ "test.wav";
	~inBuf=Buffer.read(s,~infilep,action:{|...args| \inbuf.postln;args.postln;});
	~outBuf = Buffer.allocConsecutive(13, s,2**18,1);
	s.sync;
	analNode=Synth.new(\transect12__1,[\inbuf,~inBuf, \outbuf, ~outBuf],s);
	NodeWatcher.register(analNode);
	~state=(
		analNode:analNode
	);
};
)
/*
//completionMessage hoohah looks like this:

y = Synth.basicNew(\help_Buffer); // not sent yet
b = Buffer.readNoUpdate(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav",
    completionMessage: { arg buffer;
        // synth add its s_new msg to follow
        // after the buffer read completes
        y.newMsg(s,[\bufnum, buffer],\addToTail)
    });
*/