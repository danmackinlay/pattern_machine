// based on MCLD's example MCLD_Genetic tests

PSBasicJudgeSynths {
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*loadSynthDefs {
		//first, a simple connector to siphon one bus into another.
		SynthDef.new(\jack, { |in, out|
			Out.ar(out, In.ar(in));
		}).add;
		// This judge is one of the simplest I can think of (for demo purposes) 
		// - evaluates closeness of pitch to a reference value (800 Hz).
		SynthDef.new(\ps_listen_eight_hundred, { |in, out, active=0, t_reset=0, i_leakcoef=1.0, i_targetpitch=800|
			var testsig, comparison, integral, freq, hasFreq, logtargetpitch, realleakcoef;
			logtargetpitch = i_targetpitch.log;
			testsig = LeakDC.ar(Mix.ar(In.ar(in, 1)));
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
	}
}
