/*
synths that do delay, echo, grain stuff.

TODO: bufRd versions of the DelTapRd synths.
*/
PSBufDelaySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		//Looping delay - sample and hold, e.g. a bar.
		SynthDef.new(\ps_deltapwr_loop__1x1, {
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
		SynthDef.new(\ps_deltaprd_simple_play__1x2, {
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
		SynthDef.new(\ps_deltaprd_play__1x2, {
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
		//Delay grain - plays snippets of a (static) buffer, with bending
		SynthDef.new(\ps_bufrd_play__1x2, {
			arg out=0,
			bufnum,
			deltime=0.0,
			rate=1.0, modulate=0, modlag=0.5,
			pan=0, amp=1, gate=1,
			attack=0.01, decay=0.1, sustain=1.0, release=0.5;
			
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
			deltime = deltime + ((1-rate) * Sweep.ar(gate, 1));
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			deltime = Clip.ar(deltime, 0, BufDur.kr(bufnum));
			sig = PlayBuf.ar(
				numChannels:1,
				bufnum:bufnum,
				rate: BufRateScale.kr(bufnum) * rate,
				trigger: gate,
				startPos: BufSampleRate.kr(bufnum)*deltime,
				loop: 1, //Is this actually loop TIME?
				doneAction: 0,
			) * env;
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;
	}
}