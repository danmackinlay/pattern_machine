+ TempoClock {
	//utility conversions
	beats2freq {|beats| this.tempo / beats}
	freq2beats {|freq| this.tempo / freq}
}