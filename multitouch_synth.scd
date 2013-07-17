(
//GO!
fork {
	//needs an envelope
	SynthDef.new(\bufferbitz, {|out=0, gate=1, xpos, ypos, buf|
		var sig;
		sig = Warp1.ar(
			numChannels:1,
			bufnum:buf,
			pointer:xpos,
			freqScale:1,
			windowSize:0.2,
			windowRandRatio:0.1,
			mul: 0.1
		);
		sig = sig * EnvGen.kr(Env.asr, gate, doneAction:2);
		Out.ar(0, sig);
	}, metadata:(specs: (xpos: \unipolar, ypos: \midfreq))).add;
	s.sync;
	~soundbuf = Buffer.read(s,"/Users/dan/src/sc/f_lustre/chimegongfrenzy.aif");
	s.sync;

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
	OSCdef.newMatching(\touchset, ~tuioSetterFn, "/tuio/2Dcur", recvPort: 3333, argTemplate:["set"]);
	OSCdef.newMatching(\touchalive, ~tuioAliverFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["alive"]);
	OSCdef.newMatching(\touchupdate, ~tuioWorkerFn, "/tuio/2Dcur", recvPort: 3333, argTemplate: ["fseq"]);
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
