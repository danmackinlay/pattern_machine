//Multichannel stuff
PSMCJack {
	classvar <maxChannels = 16;
	classvar <nameBase = "jack";
	
	*initClass{
		StartUp.add({
			this.loadSynthDefs
		});
	}
	*synthName {|numChannels=1|
		^(nameBase ++ "$$" ++ numChannels.asString);
	}
	*n {|numChannels=1|
		//convenience alias for synthName
		^this.synthName(numChannels);
	}
	*loadSynthDefs {
		//first, a simple connector to siphon one bus into another.
		(1..(maxChannels+1)).do({|numChannels|
			this.makeSynthDef(numChannels).add;
		});
	}
	*makeSynthDef {|numChannels|
		^SynthDef.new(this.synthName(numChannels), { |in, out|
			Out.ar(out, In.ar(in, numChannels));
		});
	}
}