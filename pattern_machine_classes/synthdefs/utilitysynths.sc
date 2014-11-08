PSUtilitySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		SynthDef.new(\limi__1x1, {|out=0, i_cutoff=30, pregain=1|
			ReplaceOut.ar(
				out,
				Limiter.ar(
					HPF.ar(
						in: In.ar(out, 1),
						freq: i_cutoff,
						mul: pregain
					),
					1,
					0.01
				)
			)
		}).add;
		SynthDef.new(\limi__2x2, {|out=0, i_cutoff=30, pregain=1|
			ReplaceOut.ar(
				out,
				Limiter.ar(
					HPF.ar(
						in: In.ar(out, 2),
						freq: i_cutoff,
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
		SynthDef.new(\playbuf__1x2,
			{|out=0,
				bufnum,
				loop=1,
				gate=1,
				rate=1,
				pan=0|
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
			Out.ar(out, Pan2.ar(sig*env, pan));
		}).add;
		SynthDef(\soundin__1x1, {|out=0, in=0|
			Out.ar(out, SoundIn.ar(in));
		}).add;
		//play a recording or the mic, looped either way;
		//I do this often enough for it to deserve a synthdef.
		SynthDef.new(\playbuf_or_live__1x1,
			{|out=0,
				bufnum,
				loop=1.0,
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
			sig = XFade2.ar(sig, In.ar(out), livefade);
			env = EnvGen.kr(
				Env.asr(attackTime:0.05, releaseTime:0.05, curve: \sine),
				levelScale: 1,
				gate: gate,
				doneAction: 2
			);
			ReplaceOut.ar(out, sig*env);
		}).add;
		//a version which plays live input or looped buffer
		//this could also be declicked
		//todo: loop audio as well
		SynthDef.new(\bufrd_or_live__1x1,
			{|out=0,
				bufnum,
				gate=1,
				rate=1,
				trig=1,
				livefade=0.0,
				looptime=5.0,
				offset=0.0,
				loop=1.0, //who knows what this does?
				fadetime=0.2|
			var env, sig, phase, sampoffset;
			sampoffset = BufSampleRate.kr(bufnum) * offset;
			phase = Phasor.ar(
					trig: 1, //trig,
					rate: BufRateScale.kr(bufnum) * rate,
					start: 0,
					end: BufSampleRate.kr(bufnum) * looptime);
			phase = phase + sampoffset;
			//phase.poll(2, 'ph');
			sig = BufRd.ar(
				numChannels: 1,
				bufnum: bufnum,
				phase: phase,
				loop: loop, //what the shit does this do?
				interpolation: 1);
			livefade = VarLag.kr(
				in: livefade.linlin(0.0,1.0,-1.0,1.0),
				time: fadetime, warp: \linear);
			sig = XFade2.ar(sig, In.ar(out), livefade);
			env = EnvGen.kr(
				Env.asr(attackTime:0.05, releaseTime:0.05, curve: \sine),
				levelScale: 1,
				gate: gate,
				doneAction: 2
			);
			ReplaceOut.ar(out, sig*env);
		}).add;
		SynthDef(\rec_or_live__1, {|bufnum=0, in=0|
			RecordBuf.ar(In.ar(in),bufnum:bufnum, loop:0, doneAction:2);
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