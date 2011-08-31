//Multichannel stuff

//Can this class truly be necessary? 26 lines of code to plug *n* busses into
//*n* other buses? 
PSMCCore {
	classvar <maxChannels = 16;
	classvar <nameBase = "core";
	
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

//Can THIS class be truly necessary? To plug *n* in buses into 1 output bus?
PSMCMix : PSMCCore {
	classvar <maxChannels = 16;
	classvar <nameBase = "mix";
	
	*makeSynthDef {|numChannels|
		^SynthDef.new(this.synthName(numChannels), { |in, out|
			Out.ar(out, Mix.ar(In.ar(in, numChannels)));
		});
	}
}