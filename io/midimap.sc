MIDIPercMap {
	classvar <map;
	*doesNotUnderstand {|selector ... args|
		^this.map[selector]
	}
	*keys{^this.map.keys}
}
GeneralMIDIPercMap : MIDIPercMap {
	classvar <map;
	//Playing General MIDI percussion? look up its note number by name here
	*initClass {
		map = (
			\bass_drum_2: 35,
			\bass_drum_1: 36,
			\rimshot: 37,
			\snare_drum_1: 38,
			\hand_clap: 39,
			\snare_drum_2: 40,
			\low_tom_2: 41,
			\closed_hi_hat: 42,
			\low_tom_1: 43,
			\pedal_hi_hat: 44,
			\mid_tom_2: 45,
			\open_hi_hat: 46,
			\mid_tom_1: 47,
			\high_tom_2: 48,
			\crash_cymbal_1: 49,
			\high_tom_1: 50,
			\ride_cymbal_1: 51,
			\chinese_cymbal: 52,
			\ride_bell: 53,
			\tambourine: 54,
			\splash_cymbal: 55,
			\cowbell: 56,
			\crash_cymbal_2: 57,
			\vibra_slap: 58,
			\ride_cymbal_2: 59,
			\high_bongo: 60,
			\low_bongo: 61,
			\mute_high_conga: 62,
			\open_high_conga: 63,
			\low_conga: 64,
			\high_timbale: 65,
			\low_timbale: 66,
			\high_agogo: 67,
			\low_agogo: 68,
			\cabasa: 69,
			\maracas: 70,
			\short_whistle: 71,
			\long_whistle: 72,
			\short_guiro: 73,
			\long_guiro: 74,
			\claves: 75,
			\high_wood_block: 76,
			\low_wood_block: 77,
			\mute_cuica: 78,
			\open_cuica: 79,
			\mute_triangle: 80,
			\open_triangle: 81,
		);
	}
}
MicrotonicMIDIPercMap : MIDIPercMap {
	//Playing Sonic Charge's Mucrotonic?
	classvar <map;
	
	*initClass {
		map = (
			\bass_drum_1: 36,
			\bass_drum_2: 37,
			\rimshot: 38,
			\hand_clap: 39,
			\snare_drum_1: 40,
			\ride_cymbal_1: 41,
			\closed_hi_hat: 42,
			\pedal_hi_hat: 44,
		);
	}
}