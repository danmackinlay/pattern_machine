(
~dels = List.new;
~testp = Pbind(
	\delta, Pseq([1,1/2,1/2],4));
~testp2 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],4),
), disorder: Pstep(Pseq([0,1]),4,1));
~testp3 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],8),
), disorder: Pstep(Pseq([0,1]),4,2));
)
~testp2.trace.play;
//doesn't work because Pstep accesses thread variables; naughty.
//~testp3.trace.asStream.nextN(60, Event.default.copy)
//instead
~testp3.collect({|ev| ~dels.add(ev.delta); ev;}).play;
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
