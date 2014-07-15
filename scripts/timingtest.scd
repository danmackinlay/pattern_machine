(
~dels = List.new;
~testp = Pbind(
	\delta, Pseq([1,1/2,1/2],4));
~testp2 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],8),
), disorder: Pstep(Pseq([1,0]),4,2));
)
//doesn't work because Pstep accesses thread variables; naughty.
//~testp2.asStream.nextN(60, Event.default.copy)
//instead
~testp3 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],8),
), disorder: Pstutter(6,Pseq([1,0],2)));
~testp3.asStream.nextN(60, Event.default.copy).select(_.notNil).collect(_.delta).inject([0,0],{|a,b|a ++ [a.last+b]});

(
~testp4 = Pbind(
	\dur, Pseq([0.4, 0.2, 0.2, 0.2], 8),
	\degree, Pseq([0,2,4,8], 8)
);
)
~testp4.trace.play;
Pquantize(~testp4, quant: 1/2).trace.play;
Pquantize(~testp4, quant: 1/2, strength:Pn(0.5,5)).trace.play;
Pquantize(~testp4, quant: 1/2,  strength:Pseries(step:0.04, length: inf)).trace.play;

PexpR(0.5, 500).asStream.nextN(60)
