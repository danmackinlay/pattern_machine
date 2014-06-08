var loadSynths = {|server=nil|
server = server ?? {server.default;};
server.waitForBoot ({
	SynthDef(\snip,
		{|out=0, pitchRatio=1, amp=1.0, attackTime=0.05, releaseTime=1.0, sampleStartPos=0, buf=0, pos=0|
			var env,playr;
			env = EnvGen.kr(
				Env.perc(attackTime, releaseTime),
				levelScale: amp,
				gate: 1,
				doneAction: 2
			);
			playr = Pan2.ar(
				PlayBuf.ar(
					numChannels:1,
					bufnum:buf,
					rate: pitchRatio*BufRateScale.kr(buf),
					trigger: 1,
					startPos: sampleStartPos*BufSampleRate.kr(buf),
				),
				pos: pos,
				level: env
			);
			Out.ar(out, playr);
		},
		[],
	).add;
	SynthDef(\snip__8,
		{|out=0, pitchRatio=1, amp=1.0, attackTime=0.05, releaseTime=1.0, sampleStartPos=0, buf=0, pos=0, i_dist=0|
			var env, playr, panned;
			env = EnvGen.kr(
				Env.perc(attackTime, releaseTime),
				levelScale: amp,
				gate: 1,
				doneAction: 2
			);
			playr = Pan2.ar(
				PlayBuf.ar(
					numChannels:1,
					bufnum:buf,
					rate: pitchRatio*BufRateScale.kr(buf),
					trigger: 1,
					startPos: sampleStartPos*BufSampleRate.kr(buf),
				),
				pos: pos,
				level: env
			);
			// DIY 4-way panning
			//i_dist goes from 0 (all front) to 3 (all back)
			panned = 4.collect({|i|
				((i-i_dist).abs.min(1)*pi/2).cos * playr
			}).flat;
			Out.ar(out, panned);
		},
		[],
	).add;
});
};
loadSynths.value;