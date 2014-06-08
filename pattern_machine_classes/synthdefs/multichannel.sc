//Multichannel stuff

/*
(
//multichannelising tests
SynthDef.new(\testoffsets, {|outs| Out.ar(outs, DC.ar(2.pow((0..3))))}).add;
SynthDef.new(\sumins, {|ins, outbus| Out.kr(outbus, A2K.kr(Mix.new(In.ar(ins))))}).add;
~mctestouts = Bus.audio(s, 4);
~mcrezout = Bus.control(s, 1);
~mcplaygroup = Group.head(s);
~mclistengroup = Group.after(~mcplaygroup);
~mcplaysynth = Synth.new(\testoffsets, [\outs, ~mctestouts], ~mcplaygroup);
~mclistensynth = Synth.new(\sumins, [\ins, ~mctestouts, \outbus, ~mcrezout], ~mclistengroup);
~mcrezout.get(_.postln);
(1..17).do({|numChannels|
	SynthDef.new('jack__' ++ numChannels.asString, { |in, out|
	Out.ar(out, In.ar(in, numChannels));
	}).add;
});
PSSynthDefPhenotype.map
"nameBase" ++ "__" ++ 4.asString
)
*/

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
		^(nameBase ++ "__" ++ numChannels.asString);
	}
	*n {|numChannels=1|
		//convenience alias for synthName
		^this.synthName(numChannels);
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
			Out.ar(out, Mix.new(In.ar(in, numChannels)));
		});
	}
}