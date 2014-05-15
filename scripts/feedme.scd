s=~serverboot.(prox:\local, device:\internal);
~plotmags = {|buf, lbl| buf.loadToFloatArray(action:{|data| {data[0,2..]  .max(0.000001)  .log.normalize  .plot(lbl)}.defer})};

(
var feedState = ~feedState = (\foo: 0.6);
fork {
	SynthDef(\unFB,
		{|out=0,
			delaytime=0.1,
			gain=0.0,
			headroom=6.0,
			slowSmooth=0.99,
			fastSmooth=0.9,
			fft1,
			fft2,
			fft3,
			fft4,
			fft5|
			var origChain, slowChain, fastChain, peakChain, maskChain, maskedChain;
			origChain = FFT(
				fft1,
				DelayN.ar(
					In.ar(out),
					maxdelaytime: 1,
					delaytime: delaytime,
					mul: gain.dbamp
				)
			);
			slowChain = PV_MagSmooth(
				PV_Copy(origChain, fft2),
				slowSmooth);
			fastChain = PV_MagSmooth(
				PV_Copy(origChain, fft3),
				fastSmooth);
			maskChain = PV_MagMulAdd(
				PV_Copy(slowChain, fft4),
				headroom.dbamp);
			peakChain = PV_Max(
				PV_Copy(maskChain, fft5),
				fastChain);
			maskChain = PV_MagDiv(maskChain, peakChain);
			origChain = PV_MagMul(origChain, maskChain);
			ReplaceOut.ar(out,
				Limiter.ar(IFFT(origChain))
			);
		},
		[],
	).add;
	SynthDef(\soundin,
		{|in=0, out=0|
			Out.ar(out, SoundIn.ar(in));
		}
	).add;
	~fft1 = Buffer.alloc(s, 2048);
	~fft2 = Buffer.alloc(s, 2048);
	~fft3 = Buffer.alloc(s, 2048);
	~fft4 = Buffer.alloc(s, 2048);
	~fft5 = Buffer.alloc(s, 2048);
	s.sync;
	~fb = Synth.new(\unFB,[
		\fft1, ~fft1,
		\fft2, ~fft2,
		\fft3, ~fft3,
		\fft4, ~fft4,
		\fft5, ~fft5,
		\delay, 0.3],
		s,\addToTail);
	Synth.new(\soundin,[],
		s,\addToHead);
};
)
~fb.set(\delay, 0.6);
~plotmags.(~fft1, \base);
~plotmags.(~fft2, \slow);
~plotmags.(~fft3, \fast);
~plotmags.(~fft4, \mask);
~plotmags.(~fft5, \peak);
~state.sampLen;
~state[\baseVal]= (-1);
~state[\baseVal]= (1);
~state[\baseCorr]= 0.8;
~state.meanDb=(-8);
~state.baseDelta=1/2;
~state.baseCorr;
~state.baseVal;

