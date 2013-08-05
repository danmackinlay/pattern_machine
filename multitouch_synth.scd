/*
 * TODO:
 *
 * multichannel playing
 * better visualisation than manual FFT. Fuck FFT.
    * could use SCMIR+MFCC, but not convinced about it being a real cepstral transform. Looks like the FFT of a multiband spectrum. Or if not, the documentation is so bad that I am alarmed anyway.
 * fit to API at ICST (nearly done!)
 * pause synths if CPU load is too heavy?
 * detect (and visualise) noisiness?
 * detect when Gate has closed
 * shell script to launch this
 * web version
 */
(
////////// Analysing sounds
fork {
	var n_chromabands=12, n_bpbands_oct=12, duration=5.0, pollrate=50.0;
	var a_bpbandf, n_bpbands_total=n_bpbands_oct*7+1;
	var n_steps = duration*pollrate+1;
	var visualiser = NetAddr.new("127.0.0.1", 3334);
	//frequencies from 55 to 7040 Hz
	a_bpbandf = 2**(Array.series(n_bpbands_total)/n_bpbands_oct)*55;
	~a_bpbandf = a_bpbandf;
	SynthDef.new(\longtrigger, {|t_go=0, bus=0, dur=(duration)|
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
	~startAnalysis = {
		~bands = Array.new(n_steps);
		~bandtimes = Array.new(n_steps);
		~nextBandRow = Array.newClear(n_bpbands_total);
		~chroma = Array.new(n_steps);
		~chromatimes = Array.new(n_steps);
		~timeStep = -1;
		~nextChromaRow = Array.newClear(12);
		~trigger.set(\t_go,1);
		visualiser.sendMsg("/vizInit", n_bpbands_total, n_steps, duration, pollrate);
	};
	~fn_bandLogger = {|msg, time, addr, port|
		var path, nid, tid, val;
		# path, nid, tid, val = msg;
		(tid==0).if({
			~timeStep = ~timeStep + 1;
			visualiser.sendMsg("/vizInit", n_bpbands_total, n_steps, duration, pollrate);

			~bandtimes = ~bandtimes.add(val);
			~nextBandRow = Array.newClear(n_bpbands_total);
			~bands = ~bands.add(~nextBandRow);
		},{
			~nextBandRow[tid-1]=val;
		});
	};
	~fn_chromaLogger = {|msg, time, addr, port|
		var path, nid, tid, val;
		# path, nid, tid, val = msg;
		(tid==0).if({
			~chromatimes = ~chromatimes.add(val);
			~nextChromaRow = Array.newClear(12);
			~chroma = ~chroma.add(~nextChromaRow);
		},{
			~nextChromaRow[tid-1]=val;
		});
	};

	OSCdef.newMatching(\pollchroma, ~fn_chromaLogger, "/tr", argTemplate:[~chromaanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollbands, ~fn_bandLogger, "/tr", argTemplate:[~bandanalyser.nodeID, nil, nil]);
	s.sync;
	~initAnalysis.value();
	//	visualiser.sendMsg("/vizStop");
	s.sync;
}
)
(
////////////Playing sounds
fork {
	SynthDef.new(\bufferbitz, {|out=0, gate=1, i_binsize=512, xpos, ypos, buf|
		var sig, freq, delay;
		//map the frequency as if out input y coord maps from the bottom of an FFT bit
		freq = ypos.linexp(0,1,55,7040);
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

	~fn_tuioSetter = {|message, time, add, port|
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
	~fn_tuioAliver = {|message, time, add, port|
		//This one just has to kill dead blobs
		var prevLiving, nowLiving;
		nowLiving = message.copyRange(2,message.size).as(IdentitySet);
		prevLiving = ~touchCoords.keys.as(IdentitySet);
		~touchesToStop = (prevLiving-nowLiving);
		~touchesToStart = (nowLiving-prevLiving);
	};
	~fn_tuioWorker = {|message, time, add, port|
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
	OSCdef.newMatching(\touchset, ~fn_tuioSetter, "/tuio/2Dcur", recvPort: 3333, argTemplate:["set"]);
	OSCdef.newMatching(\touchalive, ~fn_tuioAliver, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["alive"]);
	OSCdef.newMatching(\touchupdate, ~fn_tuioWorker, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["fseq"]);
}
)
(
~trigger.set(\t_go,1);
~triggerBus.get(_.postln);
)
s.record;
s.stopRecording
(
//STOP!
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
OSCdef(\touchupdate).free;
)
~touchSynths;
~touchCoords;
