PSReverbSynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		//Reverb unit with bonus dry sidemix
		SynthDef(\ps_freeverbside__2_2, {
			|outbus=0, wet=1, room=0.15, damp=0.8, amp=1.0, sidebus=0, sidebusAmp=1, index=0|
			var signal;
			signal = In.ar(outbus, 2);
			signal = FreeVerb2.ar(
				signal[0],
				signal[1],
				mix: wet,
				room: room*(index/100 +1),
				damp: damp,
				mul: amp
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
			);
		}).add;
		//Reverb unit with bonus dry sidemix
		SynthDef(\ps_gverbside__2_2, {
			|outbus=0, wet=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel=1.0, earlyreflevel=0.5, sidebus=0, sidebusAmp=1, index=0|
			var drysig, wetsig;
			drysig = In.ar(outbus, 2);
			wetsig = drysig.collect({|chan|
				GVerb.ar(
					chan,
					roomsize: roomsize*(index/100 +1),
					damping: damping,
					taillevel: taillevel,
					revtime: revtime*(index/100 +1),
					drylevel: 0,
					maxroomsize:400,
					earlyreflevel:earlyreflevel,
				)[0]; //thow out a channel
			})*amp;
			ReplaceOut.ar(outbus,
				XFade2.ar(drysig,wetsig,wet.linlin(0,1,-1,1)) + (In.ar(sidebus, 2)*sidebusAmp);
			);
		}).add;
		SynthDef(\ps_gverb__2_2, {
			|outbus=0, wet=1, roomsize=200, damping=0.4, amp=1.0, revtime=3, taillevel=1.0, earlyreflevel=0.5, index=0|
			var drysig, wetsig;
			drysig = In.ar(outbus, 2);
			wetsig = drysig.collect({|chan|
				GVerb.ar(
					chan,
					roomsize: roomsize*(index/100 +1),
					damping: damping,
					taillevel: taillevel,
					revtime: revtime*(index/100 +1),
					drylevel: 0,
					maxroomsize:400,
					earlyreflevel:earlyreflevel,
					mul: amp,
				)[0]; //thow out a channel
			})*amp;
			ReplaceOut.ar(outbus,
				XFade2.ar(drysig,wetsig,wet.linlin(0,1,-1,1))
			);
		}).add;
		// DIY diffuser
		//TODO: the only way to make this sane is 4 rolling comb filters, input enveloped
		//TODO: recirculation delay
		SynthDef.new(\ps_mutatingreverb__1_1, {
			|outbus,
			dry=0,
			lforate=0.21,
			delay=0.01,
			gain=0.15,
			gainvar=0.5,
			delvar=0.5|
			var sig,sigA, sigB, phaseA, trigA, trigB, envA, envB, delLo, delHi, gainLo, gainHi;
			phaseA = LFSaw.kr(lforate);
			trigA = phaseA < 0;
			trigB = phaseA >= 0;
			envA = CentredApprox.halfCos(phaseA);
			envB = CentredApprox.halfCos((phaseA+1).wrap2(1));
			delLo = delay*(1-delvar);
			delHi = delay*(1+delvar);
			gainLo = gain*(1-gainvar);
			gainHi = gain*(1+gainvar).min(1.5);
			sig = In.ar(outbus);
			sigA = DoubleNestedAllpassL.ar(sig,
				maxdelay1: 0.5,
				delay1: TRand.kr(delLo, delHi, trig:trigA),
				gain1: TRand.kr(gainLo, gainHi, trig: trigA)*envA,
				maxdelay2: 0.5,
				delay2: TRand.kr(delLo, delHi, trig:trigA),
				gain2: TRand.kr(gainLo, gainHi, trig: trigA)*envA,
				maxdelay3: 0.5,
				delay3: TRand.kr(delLo, delHi, trig:trigA),
				gain3: TRand.kr(gainLo, gainHi, trig: trigA)*envA,
				mul: 1, add: 0);
			sigB = DoubleNestedAllpassL.ar(sig,
				maxdelay1: 0.5,
				delay1: TRand.kr(delLo, delHi, trig:trigB),
				gain1: TRand.kr(gainLo, gainHi, trig: trigB)*envB,
				maxdelay2: 0.5,
				delay2: TRand.kr(delLo, delHi, trig:trigB),
				gain2: TRand.kr(gainLo, gainHi, trig: trigB)*envB,
				maxdelay3: 0.5,
				delay3: TRand.kr(delLo, delHi, trig:trigB),
				gain3: TRand.kr(gainLo, gainHi, trig: trigB)*envB,
				mul: 1, add: 0);
			ReplaceOut.ar(outbus, dry*sig + sigA + sigB);
		}).add;
	}
}