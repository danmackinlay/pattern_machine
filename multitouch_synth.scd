/*
 * TODO:
 *
 * multichannel playing

 * fit to API at ICST (nearly done!)
 * pause synths if CPU load is too heavy?
 * spectral improvements
   * colourise spectral display
   * detect (and visualise) noisiness vs percussiveness?
   * apply an unsharp mask to bands to get cleaner lines (looks clear enough, don't bother)
 * shell script to launch this
    * including detecting location of filepath (or env var?)
 * web version
 * ditch the i_binsize business now that we are not in Fourier domain
 * sound nicer
   * roll off higher harmonics for contrast
   * remove zipper noise from synths (mostly audible at low f in delay)
   * compressor
   * reverb. C'mon, the kids love reverb.
 */
(
////////// Config vars
~here = "/Users/dan/src/sc/f_lustre/";
~xmin=0;
~xmax=1; //4 for ICST production
~ymin=0;
~ymax=1;
~n_chromabands=12;
~n_bpbands_oct=12;
~pollrate=100.0;
~duration=10.0;
~visualizerport = 3334;
~minDb=(-45.0);
~maxDb=(-10.0);
~minF=55;
~n_octaves=7;

////////// Derived vars
~n_bpbands_total=~n_bpbands_oct*~n_octaves+1;
~maxF = 2**~n_octaves * ~minF;
//frequencies from 55 to 7040 Hz
~fmap = {|v| 2**v.linlin(~ymin,~ymax,0.0,~n_octaves)*~minF };
~posmap = {|v| 2**v.linlin(~xmin,~xmax,0.0,1.0)};
~n_steps = (~duration*~pollrate+1).asInteger;
~a_bpbandf = (Array.series(~n_bpbands_total)/~n_bpbands_total).collect(~fmap);
////////// Analysing sounds
fork {
	var visualiser = NetAddr.new("127.0.0.1", ~visualizerport);
	SynthDef.new(\longtrigger, {|t_go=0, bus=0, dur=(~duration)|
		//every time you set this input, this keeps it at 1 for dur seconds
		var gate = Trig1.kr(
			t_go,
			dur:dur
		);
		//send a trigger after a signal decrease (envelope close)
		SendTrig.kr (in: (Delay1.kr(gate)-gate), id: 0, value: gate);
		Out.kr(bus, gate);
	}).add;
	SynthDef.new(\play_buf_inst, {|gate=0, out=0, buf=0|
		Out.ar(out,
			PlayBuf.ar(1, buf,
				rate:gate, trigger:gate,
			)* EnvGen.kr(
				Env.asr(0.1,1,0.1,\linear),
				gate:gate, doneAction:0 //doesn't free synth atm
			)
		);
	}).add;
	SynthDef.new(\play_in, {|gate=0, out=0|
		Out.ar(out,
			SoundIn.ar*EnvGen.kr(
				Env.asr(0.1,1,0.1,\linear),
				gate:gate, doneAction:0 //doesn't free synth atm
			)
		);
	}).add;
	SynthDef.new(\report_chromagram, {|gate=0, inbus=0|
		var in, fft, chroma, poller, time;
		in= In.ar(inbus);
		//Timer doesn't do what I think it does. Sweep does.
		time = Sweep.kr(gate);
		poller = Impulse.kr(~pollrate)*gate;

		SendTrig.kr (in: poller, id: 0, value: time);

		fft = FFT(LocalBuf(2048), in);

		chroma=Chromagram.kr(fft, 2048, ~n_chromabands);
		chroma.do({|v, i|
			SendTrig.kr (in: poller, id: i+1, value: v);
		});
	}).add;
	SynthDef.new(\report_bands, {|gate=0, inbus=0|
		var in, amps, poller, time;
		var bwr = ~n_bpbands_total.reciprocal;

		in= In.ar(inbus);
		time = Sweep.kr(gate);
		poller = (Impulse.kr(~pollrate)*gate);

		SendTrig.kr (in: poller, id: 0, value: time);

		~a_bpbandf.do({|freq,i|
			SendTrig.kr(
				in: poller,
				id: i+1,
				value: (
					Amplitude.kr(
						Resonz.ar(in,freq,bwr)
					) * (~n_bpbands_total.sqrt)
				).ampdb
			);
		});
	}).add;
	~triggerBus = Bus.control(s,1);
	~analBus = Bus.audio(s,1);
	~listenGroup = Group.new(s);
	//~soundBuf = Buffer.read(s, ~here +/+ "chimegongfrenzy.aif");
	//~soundBuf = Buffer.read(s, ~here +/+ "note_sweep.aif");
	~soundBuf = Buffer.read(s, ~here +/+ "draingigm.wav");
	s.sync;
	~trigger = Synth.new(\longtrigger,
		[\bus, ~triggerBus, \dur, ~duration],
		target: ~listenGroup, addAction:\addBefore);
	~player = Synth.new(\play_buf_inst,
		[\out, ~analBus],
		target: ~listenGroup, addAction:\addToHead);
	~chromaanalyser = Synth.new(\report_chromagram,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);
	~bandanalyser = Synth.new(\report_bands,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);
	s.sync;
	~player.map(\gate, ~triggerBus);
	~chromaanalyser.map(\gate, ~triggerBus);
	~bandanalyser.map(\gate, ~triggerBus);
	s.sync;
	~startAnalysis = {
		~bands = Array.new(~n_steps);
		~bandtimes = Array.new(~n_steps);
		~nextBandRow = Array.newClear(~n_bpbands_total);
		~chroma = Array.new(~n_steps);
		~chromatimes = Array.new(~n_steps);
		~timeStep = -1;
		~nextChromaRow = Array.newClear(12);
		~trigger.set(\t_go,1);
		visualiser.sendMsg("/viz/init", ~n_bpbands_total, ~n_steps, ~duration, ~pollrate);
	};
	~fn_bandLogger = {|msg, time, addr, port|
		var path, nid, tid, val;
		# path, nid, tid, val = msg;
		(tid==0).if({
			~timeStep = ~timeStep + 1;
			~nextBandRow.any(_.notNil).if({
				visualiser.sendMsg("/viz/bands", *(~nextBandRow.linlin(~minDb,~maxDb,0,1).asFloat));
			});
			visualiser.sendMsg("/viz/step", val);
			~bandtimes = ~bandtimes.add(val);
			~nextBandRow = Array.newClear(~n_bpbands_total);
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

	OSCdef.newMatching(\pollchroma, ~fn_chromaLogger, "/tr", argTemplate: [~chromaanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollbands, ~fn_bandLogger, "/tr", argTemplate: [~bandanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollend, {|...args| visualiser.sendMsg("/viz/stop");}, "/tr", argTemplate: [~trigger.nodeID, 0, nil]);
	s.sync;
	~startAnalysis.value();
	s.sync;
    ////////////Playing sounds
	SynthDef.new(\harmonic_grain, {|out=0, gate=1, i_binsize=512, xpos, ypos, buf|
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
			mul: 0.2
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
			~touchSynths[k] = Synth.new(\harmonic_grain, [\xpos, coords[0], \ypos, coords[1], \buf, ~soundBuf]);
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
//STOP!
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
OSCdef(\touchupdate).free;
)
~touchSynths;
~touchCoords;
(
~trigger.set(\t_go,1);
~triggerBus.get(_.postln);
)
~startAnalysis.value();

s.record;
s.stopRecording