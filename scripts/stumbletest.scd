(
~testp = Pbind(
	\delta, Pseq([1,1/2,1/2],4));
~testp2 = Pstumble(Pbind(
	\delta, Pseq([1,1/2,1/2],4),
), disorder: Pstep(Pseq([0,1]),2,2));
)
~testp.trace.play;
~testp2.trace.play;