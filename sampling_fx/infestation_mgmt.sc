PSInfestManager {
	//model in the SimpleController setup
	//To consider:
	// How will this work with all the arpegiations and such? When it's not ust one playing? I think badly.
	// we probably want a grid manager.
	var <nBuffers=7;
	var <nSlots=8;
	var <numChannels=2;
	var <server;
	var <>group;
	var <recBufs;
	var <ins;
	var <outs;
	var <>hostSynthdef = \ps_infest_poly_host;
	var <>parasiteSynthdef = \ps_infest_poly_parasite_lfo;
	var <hostSynths;
	var <hostState;
	var <parasiteSynths;
	var <parasiteState;
	*new {
	}
	play {}
	makeHostSynth {}
	makeParasiteSynth {|buf|
		^Synth.new(parasiteSynthdef,
			[\out, outs, \gate, 1, \i_sndbuffer, buf],
			addAction:\addToTail,
			target:group);
	}
	setNote {|buffer, slot, on|

	}
}