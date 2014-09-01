PSInfestSynths {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs{
		SynthDef(\ps_infest_poly_host, {
			|in, i_sndbuffer, phaseout|
			//have a stab at recording some stuff
			RecordBuf.ar(
				inputArray: In.ar(in),
				bufnum: i_sndbuffer,
				run:1,
				loop:0,
				doneAction:2
			);
		}).add;
		SynthDef(\ps_infest_poly_parasite, {
			|out, gate=1,
			i_sndbuffer,
			phase=0,
			windowSize=0.1,
			windowRandRatio=0.1,
			attack=0.05,
			amp=1.0,
			release=0.5|
			var monosig, env;
			env = EnvGen.kr(
				Env.asr(attackTime:attack, releaseTime:release),
				gate: gate,
				doneAction: 2
			);
			monosig = Warp1.ar(
				numChannels: 1,
				bufnum: i_sndbuffer,
				pointer: phase,
				interp: 2,
				windowSize: windowSize,
				overlaps: 2,
				windowRandRatio: windowRandRatio,
				mul: env
			);
			Out.ar(out, monosig);
		}).add;
		SynthDef(\ps_infest_poly_parasite_lfo, {
			|out, gate=1,
			i_sndbuffer,
			phase=0,
			windowSize=0.1,
			windowRandRatio=0.1,
			attack=0.05,
			amp=1.0,
			release=0.5,
			lfof=1,
			lfoam=0.1,
			llfof=0.3,
			llfoa=1,
			llfoam=0.5,
			llfofm=0.5,
			lfophase=0|
			var monosig, env, lfo, llfo;
			llfo = SinOsc.kr(
				freq: llfof,
				mul: llfoa,
			);
			lfo = SinOsc.kr(
				phase: lfophase * 2 * pi,
				freq: lfof * (1 + (llfo*llfofm)),
				mul: (1+ (llfo*llfoam)),
			);
			(lfof * (1 + (llfo*llfofm))).poll(1, label:\lfof);
			env = EnvGen.kr(
				Env.asr(attackTime:attack, releaseTime:release),
				gate: gate,
				doneAction: 2
			);
			monosig = Warp1.ar(
				numChannels: 1,
				bufnum: i_sndbuffer,
				pointer: phase,
				interp: 2,
				windowSize: windowSize,
				overlaps: 2,
				windowRandRatio: windowRandRatio,
				mul: env * (1+ (lfoam * lfo))
			);
			Out.ar(out, monosig);
		}).add;
	}
}
