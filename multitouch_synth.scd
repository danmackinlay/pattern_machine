/*
 * TODO:
 *
 * multichannel playing
 * better visualisation than manual FFT. Fuck FFT.
   * could use SCMIR+MFCC, but not really convinced about it being a real cepstral transform. Looks like the a single FFT of a multiband whosit
 * fit to API at ICST
 *
 */

(
//GO!
fork {
	var n_chromabands=12, n_bpbands_oct=4, a_bpbandf;
	//frequencies from 40 to 4000 Hz
	a_bpbandf = 2**(Array.series(7*n_bpbands_oct)/n_bpbands_oct)*40;
	~a_bpbandf = a_bpbandf;
	SynthDef.new(\chromagram, {|gate=0|
		var in, fft, chroma, poller, time;

		//in = SinOsc.ar(440,0,0.1);
		in= SoundIn.ar;
		//Timer doesn't do what I think it does
		time = Sweep.kr(gate);
		poller = Impulse.kr(1)*gate;

		SendTrig.kr (in: poller, id: 0, value: time);

		fft = FFT(LocalBuf(2048), in);

		chroma=Chromagram.kr(fft, 2048, n_chromabands);
		chroma.do({|v, i|
			SendTrig.kr (in: poller, id: i+1, value: v);
		});
	}).add;
	SynthDef.new(\bands, {|gate=0|
		var in, amps, poller, time;

		in= SoundIn.ar;
		time = Sweep.kr(gate);
		poller = Impulse.kr(1)*gate;

		SendTrig.kr (in: poller, id: 0, value: time);

		a_bpbandf.do({|freq,i|
			SendTrig.kr(
				in: poller,
				id: i+1,
				value: Amplitude.kr(Resonz.ar(in,freq))
			);
		});
	}).add;

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
	~soundbuf = Buffer.read(s,"/Users/dan/src/sc/f_lustre/chimegongfrenzy.aif");
	s.sync;
	~chromaanalyser = Synth.new(\chromagram);
	~bandanalyser = Synth.new(\bands);
	s.sync;
	~chromaanalyser.set(\gate, 1);
	~bandanalyser.set(\gate, 1);
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
	//OSCdef.newMatching(\pollchroma, {|...args| [\chroma,args].postln;}, "/tr", argTemplate:[~chromaanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollbands, {|...args| [\bands,args].postln;}, "/tr", argTemplate:[~bandanalyser.nodeID, nil, nil]);
}
)
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
