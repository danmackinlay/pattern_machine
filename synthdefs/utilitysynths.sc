PSUtilitySynthDefs {
	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
    	SynthDef.new(\limi__1, {|outbus, cutoff=50, pregain=1|
    		ReplaceOut.ar(
    			outbus,
    			Limiter.ar(
    				HPF.ar(
    					in: In.ar(outbus, 1),
    					freq: cutoff,
    					mul: pregain
    				),
    				1,
    				0.01
    			)
    		)
    	}).add;
    	SynthDef.new(\limi__2, {|outbus, cutoff=50, pregain=1|
    		ReplaceOut.ar(
    			outbus,
    			Limiter.ar(
    				HPF.ar(
    					in: In.ar(outbus, 2),
    					freq: cutoff,
    					mul: pregain
    				),
    				1,
    				0.01
    			)
    		)
    	}).add;
    }
}