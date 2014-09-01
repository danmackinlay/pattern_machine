PSUtilitySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		SynthDef.new(\limi__1x1, {|out=0, cutoff=30, pregain=1|
			ReplaceOut.ar(
				out,
				Limiter.ar(
					HPF.ar(
						in: In.ar(out, 1),
						freq: cutoff,
						mul: pregain
					),
					1,
					0.01
				)
			)
		}).add;
		SynthDef.new(\limi__2x2, {|out=0, cutoff=30, pregain=1|
			ReplaceOut.ar(
				out,
				Limiter.ar(
					HPF.ar(
						in: In.ar(out, 2),
						freq: cutoff,
						mul: pregain
					),
					1,
					0.01
				)
			)
		}).add;
		SynthDef.new(\playbuf__1,
			{|out=0,
				bufnum,
				loop=1,
				gate=1,
				rate=1|
			var env,sig;
			sig = PlayBuf.ar(
				numChannels:1,
				bufnum:bufnum,
				rate: rate*BufRateScale.kr(bufnum),
				trigger: gate,
				loop: loop,
			);
			env = EnvGen.kr(
				Env.asr(attackTime:0.05, releaseTime:0.05, curve: \sine),
				levelScale: 1,
				gate: gate,
				doneAction: 2
			);
			Out.ar(out, sig*env);
		}).add;
		SynthDef(\soundin__1x1, {|out=0, in=0|
			Out.ar(out, SoundIn.ar(in));
		}).add;
		//play a recording or the mic; I do this often enough for it to deserve a synthdef.
		SynthDef.new(\playbuf_soundin__1x1,
			{|out=0,
				in=0,
				bufnum,
				loop=1,
				gate=1,
				rate=1,
				livefade=0.0,
				fadetime=0.2|
			var env,sig;
			sig = PlayBuf.ar(
				numChannels:1,
				bufnum:bufnum,
				rate: rate*BufRateScale.kr(bufnum),
				trigger: gate,
				loop: loop,
			);
			livefade = VarLag.kr(
				in: livefade.linlin(0.0,1.0,-1.0,1.0),
				time: fadetime, warp: \linear);
			sig = XFade2.ar(sig, SoundIn.ar(in), livefade);
			env = EnvGen.kr(
				Env.asr(attackTime:0.05, releaseTime:0.05, curve: \sine),
				levelScale: 1,
				gate: gate,
				doneAction: 2
			);
			Out.ar(out, sig*env);
		}).add;
		SynthDef(\rec_soundin__1, {|bufnum=0, in=0|
			RecordBuf.ar(SoundIn.ar(in),bufnum:bufnum, loop:0, doneAction:2);
		}).add;

		//ChannelMixer test thingy
		//a = voicechannels[0].play(\pinkfilt, [\freq, 2000, \rq, 0.02, \out, voiceschannels[0].in.index]);
		SynthDef.new(\pinkfilt, {
			arg out=0,	// out is the standard name used by MixerChannel
			freq, rq;
			Out.ar(out, RLPF.ar(PinkNoise.ar, freq, rq));
		}).add;
	}
}