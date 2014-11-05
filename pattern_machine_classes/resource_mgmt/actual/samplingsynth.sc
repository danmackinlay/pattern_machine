PSSamplingSynth : PSSynth {
	var <buffer, <phasebus, <recsynth, <freebus=false, <freebuf=false;
	*new{arg buf, pb;
		^super.new.initPSSamplingSynth(buf, pb);
	}
	initPSSamplingSynth {arg buf, pb; 
		buffer = buf;
		phasebus = pb;
	}
	rec {|dur=10.0|
		recsynth.set(\t_rec, dur);
	}
	setup {
		phasebus.isNil.if({
			phasebus= Bus.control(psstrip.server, 1);
			freebus = true;
		}, {
			freebus = false;
		});
		
		recsynth = (
			instrument: \ps_bufwr_resumable__1x1,
			in: psstrip.inbus,
			bufnum: buffer,
			phasebus: phasebus,
			fadetime: 0.05,
			group: psstrip.sourcegroup,
			addAction: \addToHead,
			sendGate: false,//persist
		).play;
	}
	
	free {
		recsynth.free;
		freebus.if({phasebus.free;});
		freebuf.if({buffer.free;});
	}
}