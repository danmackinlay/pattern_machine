PSUtilitySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		SynthDef.new(\limi__1, {|out, cutoff=30, pregain=1|
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
		SynthDef.new(\limi__2, {|out, cutoff=30, pregain=1|
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
			{|out,
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
		SynthDef(\soundin__1, {|out=0, in=0|
			Out.ar(out, SoundIn.ar(in));
		}).add;
		SynthDef(\rec_soundin__1, {|bufnum=0, in=0|
			RecordBuf.ar(SoundIn.ar(in),bufnum:bufnum, loop:0, doneAction:2);
		}).add;
	}
}