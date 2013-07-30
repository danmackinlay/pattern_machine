(
var trackerMaster, syphonClient;
trackerMaster = NetAddr.new("224.0.0.1", 64000);
//syphonClient= NetAddr.new("127.0.0.1", 8400);
//syphonClient.sendMsg("/SwitchSyphonClient", "someclientname", 1. );
trackerMaster.sendMsg("/trackerMaster/requestTuiostream", 3333 );

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
//STOP!
OSCdef(\touchset).free;
OSCdef(\touchalive).free;
OSCdef(\touchupdate).free;
)