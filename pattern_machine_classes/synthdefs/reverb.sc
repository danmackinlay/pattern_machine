PSReverbSynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
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
	}
}