PContext : Pattern {
	/* Looks up a key in an external state collection
	(
		~state = (a:1);
		~str =Pbind(\delta, PContext(~state, \a)).trace.play;
	)
	*/
	var <>state; //what to look up in
	var <>key; //which key to look up
	var <>default; //fallback to...
	*new { arg state, key, default;
		^super.newCopyArgs(state, key, default)
	}
	storeArgs { ^[state, key, default] }
	asStream {
		^FuncStream.new({state.at(key) ? default})
	}
}

