/*
GENERAL DEFINITION OF JUDGE SYNTHS:
A judge evaluates a signal, read from bus "testbus". Often the evaluation is done in reference to 
another signal - perhaps a "template" signal, or an aggregate. The judge must evaluate the signal's
deviation from the ideal, and output the integral of this deviation to bus "out".

Required parameters in the synth:
 * testbus - the audio bus to read from and evaluate
 * out     - the control bus on which to write the judgment value
 * active  - set to zero to "pause" the judge, and hold output constant
 * t_reset - trigger to reset the output integral back to zero

Typically you will also have some kind of "templatebus" to read from, etc.
 
*/

MCPhenosynthJudgeSynths {
	*initClass{
		StartUp.add{
			
			// This judge is one of the simplest I can think of (for demo purposes)-
			//  evaluates closeness of pitch to a reference value (660 Hz).
			SynthDef.writeOnce(\_mcp_judge_targetpitch, { |testbus, out=0, active=0, t_reset=0, targetpitch=660|
				var testsig, comparison, integral, freq, hasFreq;
				
				testsig = LeakDC.ar(In.ar(testbus, 1));
				
				# freq, hasFreq = Pitch.kr(testsig);
				
				comparison = if(hasFreq, (freq - targetpitch).abs, 1); // "1" if hasFreq==false because we don't want to encourage quietness
				
				// Divide by the server's control rate to bring it within a sensible range.
				comparison = comparison / ControlRate.ir;
				
				// Default coefficient of 1.0 = no leak. When t_reset briefly hits nonzero, the integrator drains.
				integral = Integrator.kr(comparison * active, if(t_reset>0, 0, 1));
				
				Out.kr(out, integral);
			});
			
		} // End of StartUp.add
	} // End of initClass
}

MCPhenosynthVoxSynths {
	*initClass{
		StartUp.add{
			SynthDef.writeOnce(\_mcp_vox_sine, 
				{ |out=0, freq=100|
					Out.ar(out, SinOsc.ar(freq)*0.1);
				}
			);
		} // End of StartUp.add
	} // End of initClass
}