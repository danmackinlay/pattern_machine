/* originally based on MCLD's example MCLD_Genetic tests, though the
resemblance is rapidly diminishing.

Here I keep listensynthdefs with only one signal observedbus, ie.e. that look for one
particular signal quality rather than comapring wit with an external signal.

*/

PSBasicListenSynths {
	*initClass{
		StartUp.add({
			this.classInit;
		});
	}
	*classInit{
		/* I give my *actual* class initialisation the name of classInit, for ease of consistently initialising classes
		*/
		this.loadSynthDefs;
	}
	*loadSynthDefs {
		// This judge is one of the simplest I can think of (for demo purposes)
		// - evaluates closeness of pitch to a reference value (800 Hz).
		SynthDef.new(\ps_listen_eight_hundred, { |observedbus, out, active=1, t_reset=0, i_leakcoef=1.0, i_targetpitch=800|
			var testsig, comparison, integral, freq, hasFreq, logtargetpitch, realleakcoef;
			logtargetpitch = i_targetpitch.log;
			testsig = LeakDC.ar(Mix.new(In.ar(observedbus, 1)));
			# freq, hasFreq = Pitch.kr(testsig);
			comparison = hasFreq.if(
				(7 - ((freq.log) - logtargetpitch).abs).max(0),
				0
			).squared; //squared sharpens convergence. this is a test, after all.
			// 0 if hasFreq.not because we don't want to encourage quietness

			// Divide by the server's control rate to bring it within a sensible range.
			comparison = comparison / ControlRate.ir;

			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			// i_leakcoef <1 scales this down by a certain amount of leakage per second
			realleakcoef = (i_leakcoef.log/ControlRate.ir).exp;

			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, realleakcoef));

			Out.kr(out, integral);
		}).add;
		SynthDef.new(\ps_conv_eight_hundred,
			{ |observedbus, out, active=1, t_reset=0, i_leakcoef=1.0, i_targetpitch=800|
				var testsig, comparison, integral, realleakcoef;
				testsig = LeakDC.ar(Mix.new(In.ar(observedbus, 1)));
				comparison = (
					A2K.kr(
						Lag.ar(
							Convolution.ar(
								testsig,
								SinOsc.ar(i_targetpitch),
								1024
							).abs,
							0.1
						)
					) + 0.001
				) / (
					A2K.kr(
						Lag.ar(
							testsig.abs,
							0.1
						)
					) + 0.001
				);
				comparison = comparison / ControlRate.ir;
				realleakcoef = (i_leakcoef.log/ControlRate.ir).exp;
				integral = Integrator.kr(comparison * active, if(t_reset>0, 0, realleakcoef));
				Out.kr(out, integral);
			}
		).add;
		SynthDef.new(\ps_judge_targetpitch, { |observedbus, out=0, active=0, t_reset=0, targetpitch=660|
			var testsig, comparison, integral, freq, hasFreq;

			testsig = LeakDC.ar(In.ar(observedbus, 1));

			# freq, hasFreq = Pitch.kr(testsig);
			
			// "1" if hasFreq==false because we don't want to encourage quietness
			comparison = if(hasFreq, (freq - targetpitch).abs, 1).poll(1, \foo); 

			// Divide by the server's control rate to bring it within a sensible range.
			comparison = comparison / ControlRate.ir;

			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));

			Out.kr(out, integral);
		}).add;

		// This judge aims for the fundamental pitch to vary as much as possible.
		// You may find that this tends towards white noise or similar...
		SynthDef.new(\ps_judge_movingpitch, { |observedbus, out=0, active=0, t_reset=0|
			var testsig, comparison, integral, freq, hasFreq;

			testsig = LeakDC.ar(In.ar(observedbus, 1));

			freq = A2K.kr(ZeroCrossing.ar(testsig));

			//freq.poll(5, "freq");

			// "Moving" pitch - we want the slope of the pitch to be as high as possible
			comparison = 1 / max(Slope.kr(freq).abs /* .poll(5, "slope") */, 0.0000001);
			//comparison.poll(5, "comp");

			// We want the maximum difference to equate to a slope of 1.0 per second on the integral.
			// Assuming the comparison produces 0<=x<=1, all we need do is divide by the server's control rate.
			comparison = comparison / ControlRate.ir;

			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));

			Out.kr(out, integral);
		}).add;

		// Match a specific not-quite-trivial amplitude envelope
		// Env.new([0.001, 1, 0.3, 0.8, 0.001],[0.2,0.3,0.1,0.4],'welch').test.plot
		SynthDef.new(\ps_judge_ampenv, { |observedbus, out=0, active=0, t_reset=0|
			var testsig, comparison, integral, env;

			testsig = LeakDC.ar(In.ar(observedbus, 1));

			// Alter this envelope to the one you're aiming for...
			env = EnvGen.kr(Env.new([0.001, 1, 0.3, 0.8, 0.001],[0.2,0.3,0.1,0.4],'welch'), t_reset);

			comparison = (Amplitude.kr(testsig) - env).abs;

			comparison = comparison / ControlRate.ir;

			// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
			integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));

			Out.kr(out, integral);
		}).add;
	}
}
