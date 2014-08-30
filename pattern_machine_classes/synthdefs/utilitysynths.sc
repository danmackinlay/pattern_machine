PSUtilitySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		SynthDef.new(\limi__1, {|outbus=0, cutoff=30, pregain=1|
			ReplaceOut.ar(
				outbus,
				Limiter.ar(
					HPF.ar(
						in: In.ar(outbus, 1),
						freq: cutoff,
						mul: pregain
					),
					1,
					0.01
				)
			)
		}).add;
		SynthDef.new(\limi__2x2, {|outbus=0, cutoff=30, pregain=1|
			ReplaceOut.ar(
				outbus,
				Limiter.ar(
					HPF.ar(
						in: In.ar(outbus, 2),
						freq: cutoff,
						mul: pregain
					),
					1,
					0.01
				)
			)
		}).add;
		SynthDef.new(\playbuf__1,
			{|outbus=0,
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
			Out.ar(outbus, sig*env);
		}).add;
		SynthDef(\soundin__1x1, {|outbus=0, in=0|
			Out.ar(outbus, SoundIn.ar(in));
		}).add;
		//play a recording or the mic; I do this often enough for it to deserve a synthdef.
		SynthDef.new(\playbuf_soundin__1x1,
			{|outbus=0,
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
			Out.ar(outbus, sig*env);
		}).add;
		SynthDef(\rec_soundin__1, {|bufnum=0, in=0|
			RecordBuf.ar(SoundIn.ar(in),bufnum:bufnum, loop:0, doneAction:2);
		}).add;

		//ChannelMixer test thingy
		//a = voicechannels[0].play(\pinkfilt, [\freq, 2000, \rq, 0.02, \out, voiceschannels[0].inbus.index]);
		SynthDef.new(\pinkfilt, {
			arg outbus=0,	// outbus is the standard name used by MixerChannel
			freq, rq;
			Out.ar(outbus, RLPF.ar(PinkNoise.ar, freq, rq));
		}).add;
	}
}