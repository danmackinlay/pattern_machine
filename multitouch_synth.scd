/*
 * TODO:
 *
 * multichannel playing
 * better visualisation than manual FFT. Fuck FFT.
   * could use SCMIR+MFCC, but not really convinced about it being a real cepstral transform. Looks like the a single FFT of a multiband whosit
 * fit to API at ICST
 * pause synths if CPU load is too heavy?
 * detect noisiness?
 * detect when Gate has closed
 */
(
////////// Analysing sounds
fork {
	var n_chromabands=12, n_bpbands_oct=12, duration=30, pollrate=50;
	var a_bpbandf, n_bpbands_total=n_bpbands_oct*7+1;
	var n_steps = duration*pollRate+1;
	//frequencies from 55 to 7040 Hz
	a_bpbandf = 2**(Array.series(n_bpbands_total)/n_bpbands_oct)*55;
	~a_bpbandf = a_bpbandf;
	SynthDef.new(\longtrigger, {|t_go=0, bus=0, dur=30|
		//every time you set this bus, this keeps it at 1 for dur seconds
		Out.kr(bus,
			Trig1.kr(
				t_go,
				dur:dur
			)
		);
	}).add;
	SynthDef.new(\playbuf, {|gate=0, out=0, buf=0|
		Out.ar(out,
			PlayBuf.ar(1, buf,
				rate:gate, trigger:gate,
			)* EnvGen.kr(
				Env.asr(0.1,1,0.1,\linear),
				gate:gate, doneAction:0 //doesn't free synth atm
			)
		);
	}).add;
	SynthDef.new(\playin, {|gate=0, out=0|
		Out.ar(out,
			SoundIn.ar*EnvGen.kr(
				Env.asr(0.1,1,0.1,\linear),
				gate:gate, doneAction:0 //doesn't free synth atm
			)
		);
	}).add;
	SynthDef.new(\chromagram, {|gate=0, inbus=0|
		var in, fft, chroma, poller, time;
		in= In.ar(inbus);
		//Timer doesn't do what I think it does. Sweep does
		time = Sweep.kr(gate);
		poller = Impulse.kr(pollrate)*gate;

		SendTrig.kr (in: poller, id: 0, value: time);

		fft = FFT(LocalBuf(2048), in);

		chroma=Chromagram.kr(fft, 2048, n_chromabands);
		chroma.do({|v, i|
			SendTrig.kr (in: poller, id: i+1, value: v);
		});
	}).add;
	SynthDef.new(\bands, {|gate=0, inbus=0|
		var in, amps, poller, time;
		var bwr = n_bpbands_total.reciprocal;

		in= In.ar(inbus);
		time = Sweep.kr(gate);
		poller = (Impulse.kr(pollrate)*gate);

		SendTrig.kr (in: poller, id: 0, value: time);

		a_bpbandf.do({|freq,i|
			SendTrig.kr(
				in: poller,
				id: i+1,
				value: Amplitude.kr(Resonz.ar(in,freq,bwr))
			);
		});
	}).add;
	~triggerBus = Bus.control(s,1);
	~analBus = Bus.audio(s,1);
	~listenGroup = Group.new(s);
	~soundBuf = Buffer.read(s, "/Users/dan/src/sc/f_lustre/chimegongfrenzy.aif");
	s.sync;
	~trigger = Synth.new(\longtrigger,
		[\bus, ~triggerBus, \dur, duration],
		target: ~listenGroup, addAction:\addBefore);
	~player = Synth.new(\playbuf,
		[\out, ~analBus],
		target: ~listenGroup, addAction:\addToHead);
	~chromaanalyser = Synth.new(\chromagram,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);
	~bandanalyser = Synth.new(\bands,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);
	s.sync;
	~player.map(\gate, ~triggerBus);
	~chromaanalyser.map(\gate, ~triggerBus);
	~bandanalyser.map(\gate, ~triggerBus);
	s.sync;
	OSCdef.newMatching(\pollchroma, {|...args| [\chroma,args].postln;}, "/tr", argTemplate:[~chromaanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollbands, {|...args| [\bands,args].postln;}, "/tr", argTemplate:[~bandanalyser.nodeID, nil, nil]);
	s.sync;
	~trigger.set(\t_go,1);
	s.sync;
}
)
(
////////////Playing sounds
fork {
	SynthDef.new(\bufferbitz, {|out=0, gate=1, i_binsize=512, xpos, ypos, buf|
		var sig, freq, delay;
		//map the frequency as if out input y coord maps from the bottom of an FFT bit
		freq = ypos.linlin(0,1,SampleRate.ir/2/i_binsize,SampleRate.ir/2);
		delay = freq.reciprocal;
		sig = Warp1.ar(
			numChannels:1,
			bufnum:buf,
			pointer:xpos,
			freqScale:1,
			windowSize:0.1,
			windowRandRatio:0.2,
			mul: 0.05
		);
		sig = HPF.ar(sig, freq);
		sig = CombL.ar(sig,
			maxdelaytime: i_binsize*SampleDur.ir*8,
			delaytime: delay,
			decaytime: delay*4);
		sig = sig * EnvGen.kr(Env.asr, gate, doneAction:2);
		Out.ar(0, sig);
	}, metadata:(specs: (xpos: \unipolar, ypos: \midfreq))).add;
	~touchCoords = IdentityDictionary.new;
	~touchSynths = IdentityDictionary.new;
	~touchesToStart = IdentitySet.new;
	~touchesToStop = IdentitySet.new;

	~tuioSetterFn = {|message, time, add, port|
		var k, coords;
		k = message[2];
		coords = message.copyRange(3,message.size);
		~touchCoords[k] = coords;
		~touchSynths[k].notNil.if({
			var synth = ~touchSynths[k];
			synth.set(\xpos, coords[0]);
			synth.set(\ypos, coords[1]);
		});
	};
	~tuioAliverFn = {|message, time, add, port|
		//This one just has to kill dead blobs
		var prevLiving, nowLiving;
		nowLiving = message.copyRange(2,message.size).as(IdentitySet);
		prevLiving = ~touchCoords.keys.as(IdentitySet);
		~touchesToStop = (prevLiving-nowLiving);
		~touchesToStart = (nowLiving-prevLiving);
	};
	~tuioWorkerFn = {|message, time, add, port|
		//Called after frame updates. work should happen here.
		~touchesToStop.do({|k|
			["killing",k].postln;
			~touchCoords.removeAt(k);
			~touchSynths.removeAt(k).release;
		});
		~touchesToStart.do({|k|
			var coords = ~touchCoords[k]; //should not be empty by the end of the frame
			["starting",k].postln;
			~touchSynths[k] = Synth.new(\bufferbitz, [\xpos, coords[0], \ypos, coords[1], \buf, ~soundBuf]);
		});
		~touchesToStop.makeEmpty;
		~touchesToStart.makeEmpty;
	};
	//OSCdef.newMatching(\touchset, ~tuioSetterFn, "/tuio/2Dcur", recvPort: 3333, argTemplate:["set"]);
	//OSCdef.newMatching(\touchalive, ~tuioAliverFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["alive"]);
	//OSCdef.newMatching(\touchupdate, ~tuioWorkerFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["fseq"]);
}
)

~trigger.set(\t_go,1);
~triggerBus.get(_.postln);
s.record;
s.stopRecording
~analyser.set(\gate, 0);
~analyser.nid
(
//STOP!
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
OSCdef(\touchupdate).free;
)
~touchSynths;
~touchCoords;
