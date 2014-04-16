/*
 * TODO:
 *
 * turn this into a class to make it less horribly chaotic.
 * pause unused (analysis) synths
 * switch to TCP instead of UDP to avoid dropped packets
 * spectral improvements
   * colourise spectral display to indicate chromaticity
   * detect (and visualise) noisiness vs percussiveness?
   * check pixel dimensions of the vizualiser app
   * what does weird with high amplitude bands?
 * web version
 * sound nicer
   * reverb. C'mon, the kids love reverb.
 * eliminate, or at least document, dependencies
   * Supercollider: None.
	 * build a standalone application
   * I already build a standalone for processing. But it has build dependencies
	 * oscp5
	 * syphon
 * shell script to launch this
	* including detecting location of filepath (or env var?)
 */

FLustre {
	//stuff we set often
	var <server;
	var <workingDir;
	var <nRingSpeakers;
	var <nSpeakerRings;
	var <xMin;
	var <xMax;
	var <yMin;
	var <yMax;
	var <pixWidth;
	var <pixHeight;
	var <firstOutputBus;
	var <visualizerAddress;
	var <trackerMasterAddress;
	var <syphonClientAddress;
	var <touchListenPort;
	var <sampleDisplayDuration;
	var <pollRate;
	var <minFreq;
	var <nOctaves;
	var <nBpBandsPerOctave;
	var <minDb;
	var <maxDb;
	var <debugLvl;

	//derived
	var <soundsDir;
	var <nBpBandsTotal;
	var <maxFreq;
	var <nSpeakers;
	var <freqMap;
	var <bufPosMap;
	var <xPanMap;
	var <xPosMap;
	var <yPosMap;
	var <nAnalSteps;
	var <allBpFreqs;
	var <visualizerCommand;
	var <numFrames;
	var <sampleDuration;

	//state variables dependent on real world factors.
	var <triggerBus;
	var <analBus;
	var <listenGroup;
	var <fxGroup;
	var <playGroup;
	var <compressor;
	var <soundBuf;
	var <bandAnalyser;
	var <sfPlayer;
	var <analTrigger;
	var <outputBuses;
	//java app tracking
	var <cliOutput;
	var <vizPid;
	//touch tracking
	var <touchCoords;
	var <touchSynths;
	var <touchesToStart;
	var <touchesToStop;
	//analysis vars
	var <bandAmps;
	var <bandTimes;
	var <nextBandRow;
	var <timeStep;
	
	*new {|server,
		workingDir,
		nRingSpeakers=2,
		nSpeakerRings=1,
		xMin=0, xMax=1, yMin=0, yMax=1,
		pixWidth=1280, pixHeight=720,
		firstOutputBus=0,
		visualizerAddress,
		trackerMasterAddress,
		syphonClientAddress,
		touchListenPort=3333,
		sampleDisplayDuration=10.0,
		pollRate=100.0,
		minFreq=55, nOctaves=7, nBpBandsPerOctave=12,
		minDb=(-45.0), maxDb=(-5.0),
		debugLvl=0|
		^super.newCopyArgs(
			server ?? {Server.default},
			workingDir,
			nRingSpeakers,
			nSpeakerRings,
			xMin, xMax, yMin, yMax,
			pixWidth, pixHeight,
			firstOutputBus,
			visualizerAddress ?? {NetAddr.new("127.0.0.1", 3334)},
			trackerMasterAddress ?? {NetAddr.new("224.0.0.1", 64000)},
			syphonClientAddress ?? {NetAddr.new("127.0.0.1", 8400)},
			touchListenPort,
			sampleDisplayDuration,
			pollRate,
			minFreq, nOctaves, nBpBandsPerOctave,
			minDb, maxDb,
			debugLvl
		).init;
	}
	init {
		////////// Derived vars
		soundsDir = workingDir +/+ "sounds";
		nBpBandsTotal=nBpBandsPerOctave*nOctaves+1;
		maxFreq = 2**nOctaves * minFreq;
		nSpeakers = nRingSpeakers * nSpeakerRings;
		//frequencies from minFreq to maxFreq (55 to 7040 Hz per default)
		freqMap = {|v| 2**v.linlin(yMin,yMax,0.0,nOctaves)*minFreq };
		bufPosMap = {|v| v.linlin(xMin,xMax,0.0,1.0)};
		xPanMap = {|v| v.linlin(xMin,xMax,-1.0,1.0)};
		xPosMap= {|v| v.linlin(xMin,xMax,0.0,1.0)};
		yPosMap = {|v| v.linlin(yMin,yMax,0.0,1.0)};
		nAnalSteps = (sampleDisplayDuration*pollRate+2).ceil.asInteger;
		allBpFreqs = (Array.series(nBpBandsTotal)/nBpBandsTotal).collect(freqMap);
		sampleDuration = (sampleDisplayDuration*1.1);
		visualizerCommand="open % --args width=% height=% respondport=%;pgrep -f -n FLustreDisplay".format(
			workingDir +/+ "FLustreDisplay/application.macosx/FLustreDisplay.app".shellQuote,
			pixWidth,
			pixHeight,
			touchListenPort
		);
		touchCoords = IdentityDictionary.new;
		touchSynths = IdentityDictionary.new;
		touchesToStart = IdentitySet.new;
		touchesToStop = IdentitySet.new;
	}

	initICST {
		syphonClientAddress.sendMsg("/SwitchSyphonClient", "FLustre", 1.0 );
		trackerMasterAddress.sendMsg("/trackerMasterAddress/requestTuiostream", touchListenPort);
	}
	debugPostln {|msg, lvl=1| (lvl>=debugLvl).if({msg.postln})}

	launchViz {
		//launch visualizer. We have to guess the launched PID, since the process is laundered though launchd
		cliOutput = visualizerCommand.unixCmdGetStdOut.split($@);
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
			vizPid=nil;
		}, {
			"process pid % found".format(vizPid).postln;
			vizPid;
		});
	}
	replaceSound {|relPath="note_sweep.aif"|
		soundBuf.read(soundsDir +/+ relPath,
			numFrames: numFrames,
			action: {|buf|
				//Note, the buffer *won't* actually be defined here, but rather blank
				this.debugPostln(buf.asCompileString++buf.bufnum);
				this.startAnalysis;
			}
		);
	}
	loadSynthDefs {
		SynthDef.new(\longtrigger, {|t_go=0, bus=0, dur=(sampleDuration)|
			//every time you set this input, this keeps it at 1 for dur seconds
			var gate = Trig1.kr(
				t_go,
				dur:dur
			);
			//send a trigger after a signal decrease (envelope close)
			SendTrig.kr (in: (Delay1.kr(gate)-gate), id: 0, value: gate);
			Out.kr(bus, gate);
		}).add;
		SynthDef.new(\play_buf, {|gate=0, out=0, buf=0|
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
		SynthDef.new(\report_bands, {|gate=0, inbus=0|
			var in, amps, poller, time;
			var bwr = nBpBandsTotal.reciprocal;

			in= In.ar(inbus);
			time = Sweep.kr(gate);
			poller = (Impulse.kr(pollRate)*gate);

			SendTrig.kr (in: poller, id: 0, value: time);

			allBpFreqs.do({|freq,i|
				SendTrig.kr(
					in: poller,
					id: i+1,
					value: (
						Amplitude.kr(
							Resonz.ar(in,freq,bwr)
						) * (nBpBandsTotal.sqrt)
					).ampdb
				);
			});
		}).add;
		SynthDef.new(\compressor_++(nSpeakers),
			{|in=0, thresh=0.02, slopeAbove=0.15|
				var inSig = In.ar(in, nSpeakers);
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
				maxdelaytime: minFreq.reciprocal,
				delaytime: delay,
				decaytime: delay*4);
			//gentle roll-off so that low freqencies don't have all the fun
			sig = LPF.ar(sig,
				freq: freq*2
			);
			sig = sig * EnvGen.kr(Env.asr, gate, doneAction:2);
			pannedsig = PanAz.ar(
				numChans: nRingSpeakers,
				in: sig,
				pos: xpan,
				level: 0.5,
				orientation: 0.5
			).dup(nSpeakerRings).flat; //could use PanX for a quick fade here.
			Out.ar(out, pannedsig);
		}, metadata:(specs:(
				pointer: \unipolar,
				freq: ControlSpec(minFreq, maxFreq, \exp)
		))
		).add;
	}
	initServer {
		server.waitForBoot({
			fork {
				this.loadSynthDefs;
				numFrames = server.sampleRate * sampleDuration;
				triggerBus = Bus.control(server,1);
				analBus = Bus.audio(server,1);
				listenGroup = Group.new(server);
				soundBuf = Buffer.alloc(server, numFrames, 1);
				outputBuses = Bus.new(\audio, firstOutputBus, nSpeakers, server);
				this.initICST;
				server.sync;
				//fill up with some dummy data
				soundBuf.read(soundsDir +/+ "chimegongfrenzy.aif", numFrames: numFrames, action: {|buf| {buf.plot;}.defer});
				this.debugPostln([\here,workingDir],1);
				analTrigger = Synth.new(\longtrigger,
					[\bus, triggerBus, \dur, sampleDuration],
					target: listenGroup, addAction: \addBefore);
				sfPlayer = Synth.new(\play_buf,
					[\out, analBus, \buf, soundBuf],
					target: listenGroup, addAction:\addToHead);
				bandAnalyser = Synth.new(\report_bands,
					[\inbus, analBus],
					target: listenGroup, addAction: \addToTail);
				server.sync;
				sfPlayer.map(\gate, triggerBus);
				bandAnalyser.map(\gate, triggerBus);
				OSCdef.newMatching(\pollbands, {|...argz| this.bandLogger(*argz)}, "/tr", argTemplate: [bandAnalyser.nodeID, nil, nil]);
				OSCdef.newMatching(\pollend, {|...argz| visualizerAddress.sendMsg("/viz/stop");}, "/tr", argTemplate: [analTrigger.nodeID, 0, nil]);
				//listen for notification from processing that the visualizer app has just started 
				OSCdef.newMatching(\reanalyse, {|...argz| this.startAnalysis(*argz)}, "/viz/alive");
				//launch said visualizer
				this.launchViz;
				////////////Playing sounds
				playGroup = Group.tail(server);
				server.sync;
				fxGroup = Group.after(playGroup);
				server.sync;
				//Compressor
				//You know, I could use SlopeBelow to make this a compressor+limiter.
				compressor = Synth.new(\compressor_++(nSpeakers),
					[\in, outputBuses],
					target: fxGroup,
					addAction:\addToHead
				);
				OSCdef.newMatching(\touchset, {|...argz| this.tuioSetter(*argz)}, "/tuio/2Dcur", recvPort: touchListenPort, argTemplate:["set"]);
				OSCdef.newMatching(\touchalive, {|...argz| this.tuioAliver(*argz)}, "/tuio/2Dcur", recvPort: touchListenPort, argTemplate: ["alive"]);
				OSCdef.newMatching(\touchupdate, {|...argz| this.tuioWorker(*argz)}, "/tuio/2Dcur", recvPort: touchListenPort, argTemplate: ["fseq"]);
			}
		});
	}
	startAnalysis {
		bandAmps = Array.fill(nAnalSteps,0);
		bandTimes = Array.fill(nAnalSteps,0);
		nextBandRow = Array.fill(nBpBandsTotal,0);
		timeStep = -1;
		visualizerAddress.sendMsg("/viz/init", nBpBandsTotal, nAnalSteps, sampleDisplayDuration, pollRate);
		analTrigger.set(\t_go, 1);
	}
	bandLogger {|msg, time, addr, port|
		var path, nid, tid, val;
		# path, nid, tid, val = msg;
		(tid==0).if({
			timeStep = timeStep + 1;
			nextBandRow.any(_.notNil).if({
				visualizerAddress.sendMsg("/viz/bands", *(nextBandRow.linlin(minDb, maxDb,0,1).asFloat));
			});
			visualizerAddress.sendMsg("/viz/step", val);
			bandTimes = bandTimes.add(val);
			nextBandRow = Array.fill(nBpBandsTotal,0);
			bandAmps = bandAmps.add(nextBandRow);
		},{
			nextBandRow[tid-1]=val;
		});
	}
	tuioSetter {|msg, time, add, port|
		var k, coords;
		k = msg[2];
		coords = msg.copyRange(3,msg.size);
		touchCoords[k] = coords;
		touchSynths[k].notNil.if({
			var synth = touchSynths[k];
			synth.set(\pointer, bufPosMap.value(coords[0]));
			synth.set(\freq, freqMap.value(coords[1]));
			synth.set(\xpan, xPanMap.value(coords[0]));
		});
	}
	tuioAliver {|msg, time, add, port|
		//This one just has to kill dead blobs
		var prevLiving, nowLiving;
		nowLiving = msg.copyRange(2,msg.size).as(IdentitySet);
		prevLiving = touchCoords.keys.as(IdentitySet);
		touchesToStop = (prevLiving-nowLiving);
		touchesToStart = (nowLiving-prevLiving);
	}
	tuioWorker {|msg, time, add, port|
		//Called after frame updates. Actual work should happen here.
		touchesToStop.do({|k|
			this.debugPostln(["killing",k],0);
			touchCoords.removeAt(k);
			touchSynths.removeAt(k).release;
		});
		touchesToStart.do({|k|
			var coords = touchCoords[k]; //should not be empty by the end of the frame
			this.debugPostln(["starting",k],0);

			touchSynths[k] = Synth.new(\harmonic_grain, [
				\out, outputBuses,
				\pointer, bufPosMap.value(coords[0]),
				\freq, freqMap.value(coords[1]),
				\xpan, xPanMap.value(coords[0]),
				\buf, soundBuf
			]);
		});
		touchesToStop.makeEmpty;
		touchesToStart.makeEmpty;
		//Send a list of id,x,y coords to the visualizerAddress
		visualizerAddress.sendMsg("/viz/blobs", *(
			touchCoords.keys.asArray.sort.collect({|k|
				var v=touchCoords.at(k);
				[k, xPosMap.value(v[0]), yPosMap.value(v[1])]}).flat;
		));
	}
	free {
		var killCommand = "kill %".format(vizPid);
		vizPid.isNumber.if({
			killCommand.unixCmd;
			vizPid = nil;
		});
		this.freeOsc;
		this.freeServerResources;
	}
	freeOsc {
		OSCdef(\touchset).free;
		OSCdef(\touchalive).free;
		OSCdef(\touchupdate).free;
	}
	freeServerResources  {
		listenGroup.free;
		triggerBus.free;
		analBus.free;
	}
}
