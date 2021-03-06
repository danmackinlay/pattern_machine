/*
synths that do delay, echo, grain stuff.

TODO: gated versions of ps_bufwr_phased__1x1

*/
PSBufDelaySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		//
		//Delay-Ugen-free delays, using buffers
		//
		SynthDef.new(\ps_bufwr_phased__1x1, {
			arg in=0,
			gate=1.0,
			bufnum,
			fadetime=0.0,
			phasebus;
			var env, bufSamps, bufLength, sampCount;
			bufSamps = BufFrames.kr(bufnum);
			bufLength = bufSamps* SampleDur.ir;
			in = In.ar(in,1);
			env = EnvGen.kr(
				Env.linen(
					attackTime: fadetime,
					sustainTime: (bufLength-(2*fadetime)),
					releaseTime: fadetime,
					curve: \sine),
				gate: gate,
				doneAction: 2);
			//redefine gate to include tail
			gate = (env>0);
			sampCount = Phasor.ar(
				trig: gate,
				rate: 1,
				start: 0,
				end: bufSamps);
			BufWr.ar(in, bufnum: bufnum, phase: sampCount);
			ReplaceOut.kr(phasebus, A2K.kr(sampCount*SampleDur.ir));
		}).add;
		SynthDef.new(\ps_bufwr_resumable__1x1, {
			arg in=0,
			t_rec=0.0,
			bufnum,
			fadetime=0.01,
			phasebus;
			var env, bufSamps, sampCount, gate, recTime;
			recTime = Gate.kr(t_rec, t_rec);
			gate = Trig1.kr(t_rec, recTime);
			bufSamps = BufFrames.kr(bufnum);
			in = In.ar(in,1);
			env = EnvGen.kr(
				Env.linen(
					attackTime: fadetime,
					sustainTime: (recTime-(2*fadetime)),
					releaseTime: fadetime,
					curve: \sine),
				gate: gate);
			gate = (env>0);
			sampCount = Phasor.ar(
				rate: gate, start: 0, end: bufSamps);
			BufWr.ar(in, bufnum: bufnum, phase: sampCount);
			ReplaceOut.kr(phasebus, A2K.kr(sampCount*SampleDur.ir));
		}).add;
		SynthDef.new(\ps_bufrd_phased_gated_mod__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			phasebus,
			rate=1.0, modulate=0, modlag=0.5,
			pan=0, amp=1, gate=1,
			interp=4,
			attack=0.1, decay=0.0, sustainLevel=1.0, release=0.1, maxDur=inf;
			var sig, env, baseTime, readTime, clippedGate, ramp, bufDur;
			clippedGate = gate * Trig1.kr(gate, maxDur);
			bufDur = BufDur.kr(bufnum)-SampleDur.ir;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustainLevel,
					releaseTime: release),
				gate: clippedGate,
				levelScale:amp,
				doneAction: 2);
			deltime = deltime + ((1-rate) * Sweep.ar(clippedGate, 1));
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			ramp = Phasor.ar(trig: clippedGate, rate: SampleDur.ir*rate, end: bufDur);
			baseTime = Latch.kr(In.kr(phasebus), clippedGate);
			//is the following wrap right for the last sample in the buffer?
			readTime = ((baseTime-deltime)+ramp).wrap(0, bufDur);
			sig = BufRd.ar(
				numChannels:1,
				bufnum: bufnum,
				phase: readTime*SampleRate.ir,
				interpolation: interp,
				loop: 1, // Is this actually loop TIME? or interpolation?
			) * env;
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;
		SynthDef.new(\ps_bufrd_phased_mod__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			phasebus,
			rate=1.0, modulate=0, modlag=0.5,
			pan=0, amp=1, gate=1,
			interp=4,
			attack=0.1, decay=0.0, sustainLevel=1.0, release=0.1, dur=1;

			var sig, env, baseTime, readTime, ramp, bufDur;

			gate = gate * Trig1.kr(gate, dur);
			bufDur = BufDur.kr(bufnum)-SampleDur.ir;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustainLevel,
					releaseTime: release),
				gate: gate,
				levelScale:amp,
				doneAction: 2);
			deltime = deltime + ((1-rate) * Sweep.ar(gate, 1));
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			ramp = Phasor.ar(trig: gate, rate: SampleDur.ir*rate, end: bufDur);
			baseTime = Latch.kr(In.kr(phasebus), gate);
			//is the following wrap right for the last sample in the buffer?
			readTime = ((baseTime-deltime)+ramp).wrap(0, bufDur);
			sig = BufRd.ar(
				numChannels:1,
				bufnum: bufnum,
				phase: readTime*SampleRate.ir,
				interpolation: interp,
				loop: 1, // Is this actually loop TIME? or interpolation?
			) * env;
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;
		SynthDef.new(\ps_bufrd_phased_mod_echette__1x2, {
			arg out=0,
			bufnum,
			deltime=0.0,
			phasebus,
			rate=1.0,
			modulate=0, modlag=0.5, modulateallp=0,
			pan=0, amp=1, gate=1,
			interp=4,
			attack=0.1, release=0.1,
			innerSustainDur=1, sustainDur=1, //Dur to indicate they are measured in seconds, not beats
			allpdeltime=0.1, ringtime=1;

			var sig, innerenv, outerenv, baseTime, readTime, ramp, bufDur;

			bufDur = BufDur.kr(bufnum)-SampleDur.ir;
			innerenv = EnvGen.kr(
				Env.linen(
					attackTime: attack,
					sustainTime: (innerSustainDur-attack).max(0),
					releaseTime: release),
				gate: gate,
				levelScale:amp);
			deltime = deltime + ((1-rate) * Sweep.ar(gate, 1));
			deltime = deltime + Lag2.ar(K2A.ar(modulate), lagTime: modlag);
			ramp = Phasor.ar(trig: gate, rate: SampleDur.ir*rate, end: bufDur);
			baseTime = Latch.kr(In.kr(phasebus), gate);
			//is the following wrap right for the last sample in the buffer?
			readTime = ((baseTime-deltime)+ramp).wrap(0, bufDur);
			sig = BufRd.ar(
				numChannels:1,
				bufnum: bufnum,
				phase: readTime*SampleRate.ir,
				interpolation: interp,
				loop: 1, // Is this actually loop TIME? or interpolation?
			) * innerenv;
			outerenv = EnvGen.kr(
				Env.linen(
					attackTime: 0,
					sustainTime: sustainDur,
					releaseTime: release
					),
				levelScale: 1,
				doneAction: 2,
			);
			sig = AllpassN.ar(sig,
				delaytime: allpdeltime + Lag2.ar(
					K2A.ar(modulateallp), lagTime: modlag),
				decaytime: ringtime,
				maxdelaytime: 0.5,
				mul: outerenv);
			Out.ar(out, Pan2.ar(sig, pan));
		}).add;
		//
		// DelTap-style delays, using buffers
		//
		// need control-rate phase bus
		// record
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
			ReplaceOut.kr(phasebus, phase);
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
		SynthDef.new(\ps_deltaprd_play__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			pan=0, amp=1, gate=1,
			attack=0.01, decay=0.1, sustainLevel=1.0, release=0.5, maxDur=inf,
			phasebus=1000; //set the phasebus or it no work

			var sig, env;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustainLevel,
					releaseTime: release),
				gate: gate * Trig1.kr(gate, maxDur),
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
		SynthDef.new(\ps_deltaprd_play_mod__1x2, {
			arg out=0,
			bufnum,
			deltime=1.0,
			rate=1.0, modulate=0, modlag=0.5,
			pan=0, amp=1, gate=1,
			attack=0.01, decay=0.1, sustainLevel=1.0, release=0.5, maxDur=inf,
			phasebus=1000; //set the phasebus or it no work

			var sig, env;
			env = EnvGen.kr(
				Env.adsr(
					attackTime: attack,
					decayTime: decay,
					sustainLevel: sustainLevel,
					releaseTime: release),
				gate: gate * Trig1.kr(gate, maxDur),
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
	}
}