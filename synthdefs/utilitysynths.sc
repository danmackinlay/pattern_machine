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
				buf,
				loop=1,
				gate=1,
				rate=1|
			var env,sig;
			sig = PlayBuf.ar(
				numChannels:1,
				bufnum:buf,
				rate: rate*BufRateScale.kr(buf),
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
		SynthDef(\jack__1, {|in, out|
			Out.ar(out, In.ar(in, 1));
		}).add;
		SynthDef(\jack__2, {|in, out|
			Out.ar(out, In.ar(in, 2));
		}).add;
		SynthDef(\rec__1, {|buf=0, in=0|
			RecordBuf.ar(SoundIn.ar(in),bufnum:buf,loop:0,doneAction:2);
		}).add;
	}
}