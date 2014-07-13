(
~testp = Pbind(
	\delta, Pseq([1,1/2,1/2],4));
~testp2 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],4),
), disorder: Pstep(Pseq([0,1]),4,1));
~testp3 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],4),
), disorder: Pstep(Pseq([0,1]),4,1));
)
~testp3.trace.play;
~testp2.trace.play;
