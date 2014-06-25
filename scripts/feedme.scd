/*
A wild an dangerous effect that is designed to feedback (more) safely through your microphone and PA.

*/


s=~serverboot.(prox:\local, device:\internal);
//TODO: EQ
//TODO: make safer, by ignoring shifting baseline potential
(
~plotmags = {|buf, lbl, delta=0.5|
	var task, plotter;
	buf.loadToFloatArray(action:{|data|
		{
			plotter = data[0,2..].max(0.000001).log.plot(lbl)
		}.defer;
	});
	task = Routine{
		inf.do({
			buf.loadToFloatArray(action: {|data|
				{
					plotter.value = data[0,2..].max(0.000001).log.min(2);
				}.defer;
			});
			delta.yield;
		});
	}.play;
	task;
}
)
(;
var feedState = ~feedState = (\foo: 0.6);
var fftHopSize = 512;

fork {
	SynthDef(\phaser,
		{|outbus=0,
			base=0.01,
			sens=0.0,
			attackTime=0.5,
			decayTime=0.1|
			var in, inlevel;

			in = In.ar(outbus);
			inlevel = Amplitude.ar(in, attackTime: attackTime, releaseTime: attackTime, mul: sens);

			ReplaceOut.ar(outbus,
				AllpassC.ar(in,
					maxdelaytime: 1.0,
					delaytime: base+inlevel,
					decaytime: decayTime)
			);
		},
		[],
	).add;
	SynthDef(\unFB,
		{|outbus=0,
			delaytime=0.1,
			gain=0.0,
			headroom=3.0,
			slowTime=10,
			fastTime=0.2,
			peak=(-6),
			fft1,
			fft2,
			fft3,
			fft4,
			fft5|
			var origChain, slowChain, fastChain, peakChain, maskChain, maskedChain, slowMul, fastMul, headroomChain;
			//60dB fall time
			slowMul = (1000.log.neg/
				(slowTime/
					(fftHopSize/SampleRate.ir)
				)
			).exp;
			fastMul = (1000.log.neg/
				(slowTime/
					(fftHopSize/SampleRate.ir)
				)
			).exp;
			origChain = FFT(
				fft1,
				DelayN.ar(
					In.ar(outbus),
					maxdelaytime: 1,
					delaytime: delaytime,
					mul: gain.dbamp
				)
			);
			slowChain = PV_MagSmooth(
				PV_MagSmear(
					PV_Copy(origChain, fft2),
					4
				),
				slowMul);
			fastChain = PV_MagSmooth(
				PV_Copy(origChain, fft3),
				fastMul);
			headroomChain = PV_MagMulAdd(
				PV_Copy(slowChain, fft4),
				mul: headroom.dbamp);
			peakChain = PV_Max(
				PV_Copy(headroomChain, fft5),
				fastChain);
			maskChain = PV_MagDiv(headroomChain, peakChain, zeroed:1);
			//aggressively mask
			maskChain = PV_MagSquared(maskChain);
			origChain = PV_MagMul(origChain, maskChain);
			ReplaceOut.ar(outbus,
				Limiter.ar(IFFT(origChain), level:peak.dbamp)
			);
		},
		[],
	).add;
	SynthDef(\soundin,
		{|inbus=0, outbus=0|
			Out.ar(outbus, SoundIn.ar(in));
		}
	).add;
	~fft1 = Buffer.alloc(s, 2048);
	~fft2 = Buffer.alloc(s, 2048);
	~fft3 = Buffer.alloc(s, 2048);
	~fft4 = Buffer.alloc(s, 2048);
	~fft5 = Buffer.alloc(s, 2048);
	s.sync;
	~fb = Synth.new(\unFB,[
		\outbus, 0,
		\fft1, ~fft1,
		\fft2, ~fft2,
		\fft3, ~fft3,
		\fft4, ~fft4,
		\fft5, ~fft5,
		\delay, 0.3],
		s,\addToTail);
	s.sync;
	// ~phaser = Synth.new(\phaser, [
	// 	\base, 0.1,
	// 	\sens, 0.05,
	// ], s, \addToTail);
	Synth.new(\soundin,[],
		s,\addToHead);
};
)
~fb.set(\delay, 0.6);
~fb.set(\slowTime, 20);
~plotmags.(~fft1, \base);
~plotmags.(~fft2, \slow);
~plotmags.(~fft3, \fast);
~plotmags.(~fft4, \mask);
~plotmags.(~fft5, \peak);

