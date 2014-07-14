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
var cum=0;
~cumdels = List.new;
~dels.do({|del|
	cum = cum + del;
	~cumdels.add(cum);
});
)
~cumdels

(
~testp4 = Pbind(
	\delta, Pseq([0.1, 0.05],8));
~testp5 = Pquantize(Pbind(
	\delta, Pseq([0.1, 0.05],8),
), quant: Pn(1/4, inf));
)
~testp5.trace.play;


PexpR(0.5, 500).asStream.nextN(60)
