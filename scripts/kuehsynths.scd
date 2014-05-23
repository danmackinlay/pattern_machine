var loadSynths = {|server=nil|
server = server ?? {server.default;};
s.waitForBoot ({
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
	//Reverb unit with bonus dry sidemix
	SynthDef(\freeverbside__2_2, {
		|outbus=0, mix=1, room=0.15, damp=0.8, amp=1.0, sidebus=0, sidebusAmp=1, index=0|
		var signal;
		signal = In.ar(outbus, 2);
		signal = FreeVerb2.ar(
			signal[0],
			signal[1],
			mix: mix,
			room: room*(index/100 +1),
			damp: damp,
			amp: amp
		);
		//Freeverb is a little low rent and rings a lot; phase that away
		signal = OnePole.ar(AllpassC.ar(signal,
			maxdelaytime:0.1,
			delaytime: SinOsc.ar(
				index/73+0.02,
				mul:0.005,
				add: 0.021+(index/150)),
			decaytime:0.051),
			coef: 0.5, mul: 1.5);
		signal = signal + (In.ar(sidebus, 2)*sidebusAmp);
		ReplaceOut.ar(outbus,
			signal
			//+SinOsc.ar(freq:220*(1+index), mul: 0.01)
		);
	}).add;
	//Reverb unit with bonus dry sidemix
	SynthDef(\gverbside__2_2, {
		|outbus=0, mix=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel=1.0, earlyreflevel=0.5, sidebus=0, sidebusAmp=1, index=0|
		var signal;
		signal = In.ar(outbus, 2);
		signal = signal.collect({|chan|
			GVerb.ar(
				chan,
				drylevel: 0,
				roomsize: roomsize*(index/100 +1),
				damping: damping,
				taillevel: taillevel,
				revtime: revtime*(index/100 +1),
				drylevel: 0,
				maxroomsize:400,
				earlyreflevel:earlyreflevel,
				mul: amp,
			)[0]; //thow out a channel
		});
		signal = signal + (In.ar(sidebus, 2)*sidebusAmp);
		ReplaceOut.ar(outbus,
			signal
			//+SinOsc.ar(freq:220*(1+index), mul: 0.01)
		);
	}).add.dumpUGens;
	SynthDef(\jack__2, {|inbus, outbus|
		Out.ar(outbus,In.ar(inbus, 2));
	}).add;
	SynthDef(\rec, {|buf=0, in=0|
			RecordBuf.ar(SoundIn.ar(in),bufnum:buf,loop:0,doneAction:2);
	}).add;

}, 10000);
};
loadSynths;