~make = {|onTrigFn, val=3.5|
	^Instr(
      "messyohead",
      {|in|
        LFPulse.kr(1).onTrig(
          onTrigFn,
          DC.ar(val)
        );
        in;
      },
      [\audio], \audio
    );
};
