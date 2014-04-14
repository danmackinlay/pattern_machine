/*
 * TODO:
 *
 * pause unused (analysis) synths
 * spectral improvements
   * colourise spectral display to indicate chromaticity
   * detect (and visualise) noisiness vs percussiveness?
 * web version
 * sound nicer
   * reverb. C'mon, the kids love reverb.
 * eliminate, or at least document, dependencies
   * Supercollider: None.
     * it may later require chromagram
     * build a standalone application
   * I already build a standalone for processing. But it has build dependencies
     * oscp5
     * syphon
 * shell script to launch this
    * including detecting location of filepath (or env var?)
 */
(
////////// Derived vars (from config vars loaded in a separate file)
~soundsdir = ~here +/+ "sounds";
~n_bpbands_total=~n_bpbands_oct*~n_octaves+1;
~maxF = 2**~n_octaves * ~minF;
~n_speakers = ~n_ring_speakers * ~n_speaker_rings;
//frequencies from ~minF to ~maxF (55 to 7040 Hz per default)
~fmap = {|v| 2**v.linlin(~ymin,~ymax,0.0,~n_octaves)*~minF };
~bufposmap = {|v| v.linlin(~xmin,~xmax,0.0,1.0)};
~xpanmap = {|v| v.linlin(~xmin,~xmax,-1.0,1.0)};
//~ypanmap = {|v| v.linlin(~ymin,~ymax,0.0,1.0)};
~xposmap = {|v| v.linlin(~xmin,~xmax,0.0,1.0)};
~yposmap = {|v| v.linlin(~ymin,~ymax,0.0,1.0)};
~n_steps = (~duration*~pollrate+1).asInteger;
~a_bpbandf = (Array.series(~n_bpbands_total)/~n_bpbands_total).collect(~fmap);
~outputBus = Bus.new(\audio, ~firstOutputBus, ~n_speakers, Server.default);
~initICST = {
	~syphonClient.sendMsg("/SwitchSyphonClient", "FLustre", 1.0 );
	~trackerMaster.sendMsg("/trackerMaster/requestTuiostream", ~listenPort );
};
~debugpostln = {|msg, lvl=1| (lvl>= (~debuglvl ? 0)).if({msg.postln})};
//launch visualizer. We have to guess the launched PID, since the process is laundered though launchd
~visualizercli="open % --args width=% height=% respondport=%;pgrep -f -n FLustreDisplay".format(
	~here +/+ "FLustreDisplay/application.macosx/FLustreDisplay.app".shellQuote,
	~pxwidth,
	~pxheight,
	~listenPort
);
~launchViz = {
	var cliOutput, vizPid;
	cliOutput = ~visualizercli.unixCmdGetStdOut.split($@);
	(cliOutput.size>1).if({
		//probably worked if we have a PID surrounded by @
		vizPid=cliOutput[1].asInteger;
	}, {
		//sometimes we mysteriously get a naked PID
		vizPid=cliOutput[0].asInteger;
	});
	(vizPid<=0).if({
		"oops! no PID found in output".warn;
		cliOutput.join("").warn;
		nil;
	}, {
		"process pid % found".format(vizPid).postln;
		vizPid;
	});
};
~replaceSound = {|relPath="note_sweep.aif"|
	~soundBuf.read(~soundsdir +/+ relPath, action: {|buf|
		{buf.plot;}.defer;
		~startAnalysis.value()
	});
	/*~soundBuf.read(~soundsdir +/+ relPath, action: {|buf|
		~startAnalysis.value()
	});*/
};
//~replaceSound.value("note_sweep.aif");
//~replaceSound.value("draingigm.wav");
//~replaceSound.value("chimegongfrenzy.aif");

////////// Analysing sounds
Server.default.waitForBoot({fork {
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
	/* SynthDef.new(\report_chromagram, {|gate=0, inbus=0|
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
	}).add;*/
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
	~soundBuf = Buffer.alloc(s, s.sampleRate * 30.0, 1);
	s.sync;
	~soundBuf.read(~soundsdir +/+ "chimegongfrenzy.aif", action: {|buf| {buf.plot;}.defer});

	~initICST.value;
	~debugpostln.([\here,~here],1);

	~trigger = Synth.new(\longtrigger,
		[\bus, ~triggerBus, \dur, ~duration],
		target: ~listenGroup, addAction:\addBefore);
	~player = Synth.new(\play_buf_inst,
		[\out, ~analBus],
		target: ~listenGroup, addAction:\addToHead);
	/*~chromaanalyser = Synth.new(\report_chromagram,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);*/
	~bandanalyser = Synth.new(\report_bands,
		[\inbus, ~analBus],
		target: ~listenGroup, addAction:\addToTail);
	s.sync;
	~player.map(\gate, ~triggerBus);
	//~chromaanalyser.map(\gate, ~triggerBus);
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
		~visualizer.sendMsg("/viz/init", ~n_bpbands_total, ~n_steps, ~duration, ~pollrate);
	};
	// kill the whatsit if it's already running
	// should only occur during testing.
	~stopFLustre.isFunction.if({~stopFLustre.value;});
	~stopFLustre = {
		var killer = "kill %".format(~vizpid);
		~vizpid.isNumber.if({
			killer.unixCmd;
		});
		~stopOsc.value;
		//don't do this, as we re-use them for now.
		//~freeServerResources.value;
	};
	~fn_bandLogger = {|msg, time, addr, port|
		var path, nid, tid, val;
		# path, nid, tid, val = msg;
		(tid==0).if({
			~timeStep = ~timeStep + 1;
			~nextBandRow.any(_.notNil).if({
				~visualizer.sendMsg("/viz/bands", *(~nextBandRow.linlin(~minDb, ~maxDb,0,1).asFloat));
			});
			~visualizer.sendMsg("/viz/step", val);
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
	//OSCdef.newMatching(\pollchroma, ~fn_chromaLogger, "/tr", argTemplate: [~chromaanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollbands, ~fn_bandLogger, "/tr", argTemplate: [~bandanalyser.nodeID, nil, nil]);
	OSCdef.newMatching(\pollend, {|...args| ~visualizer.sendMsg("/viz/stop");}, "/tr", argTemplate: [~trigger.nodeID, 0, nil]);
	s.sync;

    ////////////Playing sounds
	~playGroup = Group.tail(s);
	//Compressor
	//You know, I could use SlopeBelow to make this a compressor+limiter.
	SynthDef.new(\compressor_++(~n_speakers),
		{|in=0, thresh=0.02, slopeAbove=0.15|
			var inSig = In.ar(in, ~n_speakers);
			ReplaceOut.ar(in,
				Compander.ar(
					in: inSig,
					control: Mix.new(inSig),
					thresh: thresh,
					slopeAbove:slopeAbove,
					mul:((1-thresh)*slopeAbove).reciprocal
				)
			);
		}
	).add;
	s.sync;
	~fxGroup = Group.after(~playGroup);
	SynthDef.new(\harmonic_grain, {|out=0, gate=1, pointer, freq, xpan, buf|
		var sig, delay, pannedsig;
		//map the frequency as if out input y coord maps from the bottom of an FFT bit
		delay = Lag.ar(DC.ar(freq.reciprocal), 0.1);
		sig = Warp1.ar(
			numChannels:1,
			bufnum:buf,
			pointer:pointer,
			freqScale:1,
			windowSize:0.1,
			windowRandRatio:0.2,
			mul: 0.2
		);
		sig = HPF.ar(sig, freq);
		sig = CombL.ar(sig,
			maxdelaytime: ~minF.value.reciprocal,
			delaytime: delay,
			decaytime: delay*4);
		//gentle roll-off so that low freqencies don't ahve all the fun
		sig = LPF.ar(sig,
			freq: freq*2
		);
		sig = sig * EnvGen.kr(Env.asr, gate, doneAction:2);
		pannedsig = PanAz.ar(
            numChans: ~n_ring_speakers,
            in: sig,
            pos: xpan,
		    level: 0.5,
		    orientation: 0.5
		).dup(~n_speaker_rings).flat; //could use PanX for a quick fade here.
		Out.ar(~outputBus, pannedsig);
	}, metadata:(specs:(
			pointer: \unipolar,
			freq: ControlSpec(~minF, ~maxF, \exp)
	))
	).add;
	s.sync;
	~compressor = Synth.new(\compressor_++(~n_speakers),
		[\in, ~outputBus],
		target: ~fxGroup,
		addAction:\addToHead
	);
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
			synth.set(\pointer, ~bufposmap.value(coords[0]));
			synth.set(\freq, ~fmap.value(coords[1]));
			synth.set(\xpan, ~xpanmap.value(coords[0]));
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
		//Called after frame updates. Actual work should happen here.
		~touchesToStop.do({|k|
			~debugpostln.(["killing",k],0);
			~touchCoords.removeAt(k);
			~touchSynths.removeAt(k).release;
		});
		~touchesToStart.do({|k|
			var coords = ~touchCoords[k]; //should not be empty by the end of the frame
			~debugpostln.(["starting",k],0);

			~touchSynths[k] = Synth.new(\harmonic_grain, [
				\out, ~outputBus,
				\pointer, ~bufposmap.value(coords[0]),
				\freq, ~fmap.value(coords[1]),
				\xpan, ~xpanmap.value(coords[0]),
				\buf, ~soundBuf
			]);
		});
		~touchesToStop.makeEmpty;
		~touchesToStart.makeEmpty;
		//Send a list of id,x,y coords to the ~visualizer
		~visualizer.sendMsg("/viz/blobs", *(
			~touchCoords.keys.asArray.sort.collect({|k|
				var v=~touchCoords.at(k);
				[k, ~xposmap.value(v[0]), ~yposmap.value(v[1])]}).flat;
		));
	};
	OSCdef.newMatching(\touchset, ~fn_tuioSetter, "/tuio/2Dcur", recvPort: ~listenPort, argTemplate:["set"]);
	OSCdef.newMatching(\touchalive, ~fn_tuioAliver, "/tuio/2Dcur", recvPort: ~listenPort, argTemplate: ["alive"]);
	OSCdef.newMatching(\touchupdate, ~fn_tuioWorker, "/tuio/2Dcur", recvPort: ~listenPort, argTemplate: ["fseq"]);
	~stopOsc = {
		OSCdef(\touchset).free;
		OSCdef(\touchalive).free;
		OSCdef(\touchupdate).free;
	};
	~freeServerResources = {
		~listenGroup.free;
		~triggerBus.free;
		~analBus.free;
	};
	//listen for notification from processing that the visualizer app has just started up
	OSCdef.newMatching(\reanalyse, ~startAnalysis, "/viz/alive");
	//launch said visualizer
	~vizPid = ~launchViz.value;
}});
)
