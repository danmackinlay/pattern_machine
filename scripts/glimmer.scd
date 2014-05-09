/* create glimmering soundscapes without manual trweaking using machine listening.
*/
//TODO: create a version that does not depend on \findfreqs - i.e which takes a pre-filled buffer
//TODO: handle any number of input AND output channels (by being ambisonic internally?)
//TODO: turn this into an instrument with nice intuitive GUI controls etc.
//TODO: simplify.
//TODO: make feedback delay random too
//TODO: only play delayed signsl
GUI.qt;

(
var maxVoices = 23;

//This little guy voices a whole bunch of flange frequencies at a given polyphony with known rate
//input is assumed to be stereo

SynthDef.new(\glimmergrains,
	{|inbus, outbus,
		trigRate=1,
		duty=0.5,
		ringTime=0.1, wideness=1,
		attack=0.01, decay=0.5,
		freqBus,
		ratioBuf,
		intensity=1.0,
		feedbackGain = 0.0, feedbackMinLen=0.1,feedbackMaxLen=0.5|
		var in, trigRamp, voices, mixedIn, outChannels, feedback, freqEst, feedbackDepth, delayed, prenormOut;
		in = In.ar(inbus, 2);
		delayed = LocalIn.ar(2);
		feedbackDepth = feedbackMaxLen-feedbackMinLen;
		mixedIn = Mix.new(in+(delayed*feedbackGain));
		freqEst = In.kr(freqBus);
		trigRamp = LFSaw.kr(freq:trigRate, mul:0.5, add:0.5);
		voices = Array.fill(maxVoices, {|i|
			var myRamp;
			var gate, env;
			var myDelayFreq, myPan;
			var phase, pan, threshold;
			var ratioPointerDelay, ratioDelay;
			var localFreq;
			var sig;
			var alive;
			//permute phases
			phase = Rand.new;
			pan = Rand.new;
			threshold = Rand.new;
			alive = threshold<intensity;
			//voice-local phase-offset ramp
			myRamp = Wrap.kr(trigRamp + phase );
			gate = (myRamp < duty) * alive;
			env = Linen.kr(gate, attackTime: attack, releaseTime: decay);
			ratioPointerDelay = TIRand.kr(lo:0, hi: BufFrames.kr(ratioBuf), trig: gate);
			ratioDelay = BufRd.kr(1,ratioBuf, ratioPointerDelay);
			localFreq = Latch.kr(freqEst, gate);
			myDelayFreq = (localFreq* ratioDelay).max(10);
			sig = CombL.ar(
				in: mixedIn*env,
				maxdelaytime: 0.1,
				delaytime: myDelayFreq.reciprocal,
				decaytime: ringTime,
				mul:env);
			sig = DelayL.ar(
				in: sig,
				maxdelaytime: 1.0,
				delaytime: feedbackMinLen + (Rand.new*feedbackDepth)-ControlRate.ir.reciprocal
			);
			Pan2.ar(
				in: sig,
				pos: (2 * pan -1),
				level: 1.0
			);
		});
		prenormOut = Mix.new(voices);
		//Amplitude.kr(prenormOut).poll(1,\prenorm);
		outChannels = Limiter.ar(LeakDC.ar(
			prenormOut * maxVoices.sqrt.reciprocal
		),1,0.01);
		//Amplitude.kr(prenormOut).poll(1,\postnorm);
		LocalOut.ar(outChannels);
		Out.ar(outbus, outChannels);
	}
).add;
SynthDef.new(\findfreq, {|inbus, outbus|
	var hasFreq, freq;
	#freq, hasFreq = Pitch.kr(
		HPF.ar(HPF.ar(
			Mix.new(
				In.ar(inbus, 2)
			),
			freq:100), freq:100
		),
		execFreq: ControlRate.ir
	);

	Out.kr(outbus, Gate.kr(freq, hasFreq).max(10));
}).add;

~filler = {|buf,arr|
	var cont = arr.wrapExtend(512);
	buf.setn(0, cont);
	cont;
}
)
(
fork {
	~ratioBuf = Buffer.alloc(s, 512);
	// alloc and set the values
	//ratios all 1 by default.
	s.sync;
	~ratioBuf.setn(0, 1!513);
	//Now..
	s.sync;
	~filler.(~ratioBuf, [1/3,2/3,4/3,5/3]);

	~globalOuts = Bus.new(\audio, 0, 2);
	~freqBus = Bus.control(s, 1);
	~sourceIns = Bus.newFrom(s.inputBus,0,2);
	~fxGroup = Group.new(s);
	s.sync;
	//read hardware in at head of ~voxGroup
	//s.volume.gui;
	s.volume.volume= -20;
	~listener = Synth.head(~fxGroup, \findfreq, [\inbus, ~sourceIns, \outbus, ~freqBus]);
	~initArgs = [\inbus, ~sourceIns, \outbus, ~globalOuts, \freqBus, ~freqBus, \ratioBuf, ~ratioBuf];
	~fx = Synth.tail(~fxGroup, \glimmergrains, ~initArgs);
}
)

///OR, as per "http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Inconsistent-behaviour-with-MVC-updater-td7579954.html"
(
{
	~example = ();
	~example.window = Window.new.front;
	~example.window.view.decorator = FlowLayout(~example.window.view.bounds);
	\doingstuff.postln;
	~example.specs = (
		\trigRate: ControlSpec.new(0.01,10,warp:\exponential,default:1),
		\duty: ControlSpec.new(0.0,1,default:0.5),
		\ringTime: ControlSpec.new(0.01,1,warp:\exponential,default:0.1),
		\attack: ControlSpec.new(0.001,1,warp:\exponential,default:0.01),
		\decay: ControlSpec.new(0.001,1,warp:\exponential,default:0.5),
		\intensity: ControlSpec.new(0.0,1,default:0.5),
		\feedbackGain: ControlSpec.new(0.0,1,default:0.0),
		\feedbackMinLen: ControlSpec.new(0.0,1,default:0.2),
		\feedbackMaxLen: ControlSpec.new(0.0,1,default:0.4)
	);
	~example.widgets = ();
	// ~example.controlKeys = ~example.specs.keys.asList.sorted;
	~example.controlKeys = [\trigRate, \duty, \ringTime, \attack, \decay, \intensity, \feedbackGain, \feedbackMinLen, \feedbackMaxLen];

	~example.controlKeys.do({|k|
		var spec = ~example.specs[k];
		//[\settingaction, k, spec].postln;
		~example.widgets[k] = EZSlider.new(~example.window,
			controlSpec: spec,
			label: k,
			action:{|widget|
				//I suppose this could bypass the setter method
				~example.setActual(k, widget.value, false);
			}
		);
	});
	~example.controlVals = ();
	~example.specs.keysDo({|key|
		~example.controlVals[key] = ~example.specs[key].default;
	});
	~example.setActual = { arg self,k,v,updateGui=true;
		//set from actual control range
		self.controlVals[k] = v;
		self.updateSynth(k);
		updateGui.if({self.changed(k)});
	};
	~example.setUnit = { arg self,k,v,updateGui=true;
		//set 0-1.
		self.controlVals[k] = self.specs[k].map(v);
		self.updateSynth(k);
		updateGui.if({self.changed(k)});
	};
	~example.updateActions = (
		default: {|k|
			[k, ~example.controlVals[k]].postln;
			~fx.set(k, ~example.controlVals[k]);}
	);
	~example.updateSynth = {|self, k|
		var updateAction = self.updateActions[k] ? self.updateActions[\default];
		updateAction.value(k);
	};
	~example.guiupdater = Updater(~example, {arg self, name;
		var widget = ~example.widgets[name];
		{widget.value = ~example.controlVals[name];}.defer;
	});
	~example.extController = MIDIMKtl('nnkn20');
	~example.extController.esFor(\sl_1).do({|v| ~example.setUnit(\trigRate, v)});
	~example.extController.esFor(\sl_2).do({|v| ~example.setUnit(\duty, v)});
	~example.extController.esFor(\sl_3).do({|v| ~example.setUnit(\ringTime, v)});
	~example.extController.esFor(\sl_4).do({|v| ~example.setUnit(\attack, v)});
	~example.extController.esFor(\sl_5).do({|v| ~example.setUnit(\decay, v)});
	~example.extController.esFor(\sl_6).do({|v| ~example.setUnit(\intensity, v)});
	~example.extController.esFor(\kn_1).do({|v| ~example.setUnit(\feedbackGain, v)});
	~example.extController.esFor(\kn_2).do({|v| ~example.setUnit(\feedbackMinLen, v)});
	~example.extController.esFor(\kn_3).do({|v| ~example.setUnit(\feedbackMaxLen, v)});
}.defer;
)
// detach the updater when you are done
~example.guiupdater.remove;
~example.extController.elements.keys;
~example.setUnit(\intensity,1);
~example.setActual(\trigRate,6);
~example.setUnit(\trigRate,0.5);

~freqBus.get(_.postln);
~sourceIns.scope;
~fx.set(\feedbackGain, 0.2);
~ratioBuf.getn(0,512,_.postln);