//Multichannel stuff

//Can this class truly be necessary? 26 lines of code to plug *n* busses into
//*n* other buses?

PSMCCore {
	classvar <maxChannels = 16;
	classvar <nameBase = "jack";

	*initClass{
		StartUp.add({
			this.loadSynthDefs;
		});
	}
	*loadSynthDefs {
		//a simple connector to siphon one bus into another, for a few channels.
		(1..(maxChannels+1)).do({|numChannels|
			this.makeSynthDef(numChannels).add;
		});
	}
	*synthName {|numChannels=1|
		^(nameBase ++ "__%").format(numChannels);
	}
	*n {|numChannels=1|
		//convenience alias for synthName
		^this.synthName(numChannels);
	}
	*makeSynthDef {|numChannels|
		^SynthDef.new(this.synthName(numChannels), { |in, out=0|
			Out.ar(out, In.ar(in, numChannels));
		});
	}
}
