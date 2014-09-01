/*
synths that do delay, echo, grain stuff.
*/
PSResamplingSynthDefs {
	classvar log001;
	*initClass{
		log001 = 0.001.log;
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	//SC's default of specifying delays as decay times is cute, but not always what you want.
	*decayTimeFromMag{|mag, delaytime|
		^(log001*delaytime/(mag.abs.log) * (mag.sign)).clip2(1000000)
	}
	*loadSynthDefs {
		//Looping delay - sample and hold, e.g. a bar.
		SynthDef.new(\ps_buf_delay_loop__1x1, {
			arg out=0,
			deltime=1.0,
			bufnum, wet=0, fadetime=0.2,
			phasebus=1000; //NB: DO set the phase out if you don't want bleed.
			var in, partdelayed, delayed, inmix, outmix, phase;
			wet = VarLag.kr(
				in: wet.linlin(0.0,1.0,-1.0,1.0),
				time: fadetime, warp: \linear);
			in = In.ar(out,1);
			delayed = LocalIn.ar(1);
			outmix = XFade2.ar(in, delayed, wet);
			inmix = XFade2.ar(in, delayed, wet.neg);
			phase = DelTapWr.ar(bufnum, outmix);
			Out.kr(phasebus, phase);
			partdelayed = DelTapRd.ar(
				buffer:bufnum,
				phase: phase,
				delTime:(deltime - ControlRate.ir.reciprocal),//feedback correction
				interp:1, //no decay, at the expense of time drift
			);
			LocalOut.ar(partdelayed);
			ReplaceOut.ar(out, outmix);
		}).add;
		
		//Delay grain - plays snippets of the past
		SynthDef.new(\ps_buf_delay_simple_play__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			pan=0, amp=1, gate=1,
			attack=0.01, decay=0.1, sustain=1.0, release=0.5,
			phasebus=1000; //set the phasebus or it no work

			var sig, env;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustain,
					releaseTime: release),
				gate: gate,
				levelScale:amp,
				doneAction: 2);
			sig = DelTapRd.ar(
				buffer:bufnum,
				phase:In.kr(phasebus),
				delTime:deltime,
				interp: 1, //linear
				mul: env
			);
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;

		//Delay grain - plays snippets of the past, with bending
		SynthDef.new(\ps_buf_delay_play__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			rate=1.0, modulate=0, modlag=0.5,
			pan=0, amp=1, gate=1,
			attack=0.01, decay=0.1, sustain=1.0, release=0.5,
			phasebus=1000; //set the phasebus or it no work

			var sig, env;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustain,
					releaseTime: release),
				gate: gate,
				levelScale:amp,
				doneAction: 2);
			deltime = deltime + ((1-rate)*Sweep.ar(gate, 1));
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			deltime = Clip.ar(deltime, 0, BufDur.kr(bufnum));
			sig = DelTapRd.ar(
				buffer:bufnum,
				phase:In.kr(phasebus),
				delTime:deltime,
				interp: 4, //cubic
				mul: env
			);
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;
		
		SynthDef.new(\ps_echette__1x2,
			{|in=0, out=0, deltime=0.1, ringtime=1, amp=1, pan=0|
				var env, sig;
				sig = In.ar(in, 1) * EnvGen.kr(
					Env.sine(dur:deltime),
					levelScale: (ringtime/deltime).sqrt //normalises power *rate*
				);
				env = EnvGen.kr(
					Env.cutoff(
						sustainTime:deltime,
						releaseTime:ringtime
					), gate:1, doneAction:2
				);
				sig = AllpassN.ar(sig,
					delaytime: deltime,
					decaytime: ringtime,
					maxdelaytime: 0.5,
					mul: env);
				sig = Pan2.ar(sig, pos:pan);
				Out.ar(out, sig);
				}, [\ir, \ir, \ir, \ir, \ir, \ir]
		).add;
		SynthDef.new(\ps_echette_colored__1x2,
			{|in=0, out=0, deltime=0.1, ringtime=1, amp=1, freq=440, color=0.5, pan=0|
				var env, sig, combdelaytime, combdecaytime, coloramp, invpowerest;
				combdelaytime = freq.reciprocal;
				combdecaytime = this.decayTimeFromMag(color, combdelaytime);
				coloramp = color.squared;
				invpowerest = (coloramp-1)/coloramp;
				sig = In.ar(in, 1) * EnvGen.kr(
					Env.sine(dur:deltime),
					levelScale: (ringtime/deltime).sqrt //normalises power *rate*
				);
				env = EnvGen.kr(
					Env.cutoff(
						sustainTime:deltime,
						releaseTime:ringtime
					), gate:1, doneAction:2
				);
				sig = AllpassN.ar(sig,
					delaytime: deltime,
					decaytime: ringtime,
					maxdelaytime: 0.5);
				sig = CombL.ar(sig,
					maxdelaytime: 0.2,
					delaytime: combdelaytime,
					decaytime: combdecaytime,
					mul: invpowerest*env,
				);
				sig = Pan2.ar(sig, pos:pan);
				Out.ar(out, sig);
				}, [\ir, \ir, \ir, \ir, \ir, \ir, \ir, \ir]
		).add;
		
	}
}